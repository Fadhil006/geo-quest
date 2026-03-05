/**
 * GeoQuest — Cloud Functions for Firebase
 *
 * Server-side answer validation, score calculation, and session management.
 *
 * SETUP:
 *   1. cd functions/
 *   2. npm install
 *   3. firebase deploy --only functions
 *
 * These functions ensure:
 *   - Answers are validated server-side (never trust client)
 *   - Scores are calculated securely
 *   - Sessions auto-expire after 2 hours
 *   - Leaderboard updates in real-time
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

// ══════════════════════════════════════════
// 1. VALIDATE SUBMISSION
// Triggered when a new submission doc is created
// ══════════════════════════════════════════
exports.validateSubmission = functions.firestore
  .document("submissions/{submissionId}")
  .onCreate(async (snap, context) => {
    const submission = snap.data();
    const submissionRef = snap.ref;

    try {
      // Get the session
      const sessionDoc = await db.collection("sessions").doc(submission.sessionId).get();
      if (!sessionDoc.exists) {
        return submissionRef.update({ status: "error", feedback: "Session not found" });
      }
      const session = sessionDoc.data();

      // Check if session is still active
      const now = admin.firestore.Timestamp.now();
      if (!session.isActive || now.toMillis() > session.endTime.toMillis()) {
        return submissionRef.update({
          status: "rejected",
          isCorrect: false,
          pointsAwarded: 0,
          feedback: "Session has expired",
        });
      }

      // Check if challenge was already completed
      if (session.completedChallengeIds && session.completedChallengeIds.includes(submission.challengeId)) {
        return submissionRef.update({
          status: "rejected",
          isCorrect: false,
          pointsAwarded: 0,
          feedback: "Challenge already completed",
        });
      }

      // Get the correct answer
      const answerDoc = await db.collection("challenge_answers").doc(submission.challengeId).get();
      if (!answerDoc.exists) {
        return submissionRef.update({ status: "error", feedback: "Answer key not found" });
      }
      const answerData = answerDoc.data();

      // Get challenge details for points
      const challengeDoc = await db.collection("challenges").doc(submission.challengeId).get();
      const challenge = challengeDoc.data();

      // Compare answers (case-insensitive, trimmed)
      const submittedAnswer = (submission.answer || "").trim().toLowerCase();
      const correctAnswer = (answerData.answer || "").trim().toLowerCase();
      const acceptedVariants = (answerData.acceptedVariants || []).map(v => v.trim().toLowerCase());

      const isCorrect = submittedAnswer === correctAnswer || acceptedVariants.includes(submittedAnswer);

      // Calculate points with time bonus
      let pointsAwarded = 0;
      if (isCorrect) {
        const basePoints = challenge.points || 10;
        // Time bonus: up to 50% extra for fast solving
        const timeLimitMs = (challenge.timeLimitSeconds || 180) * 1000;
        const submitTime = submission.submittedAt ? submission.submittedAt.toMillis() : now.toMillis();
        // We approximate solve time as time since session's last challenge open
        pointsAwarded = basePoints; // Base; time bonus can be added with more tracking
      }

      const newScore = (session.score || 0) + pointsAwarded;
      const newTotalAnswered = (session.totalAnswered || 0) + 1;
      const newCorrectAnswers = (session.correctAnswers || 0) + (isCorrect ? 1 : 0);
      const newCompletedIds = [...(session.completedChallengeIds || [])];
      if (isCorrect) {
        newCompletedIds.push(submission.challengeId);
      }

      // Determine new difficulty
      const newDifficulty = calculateDifficulty(newScore, newCorrectAnswers / Math.max(newTotalAnswered, 1));

      // Batch update: submission result + session + leaderboard
      const batch = db.batch();

      // Update submission
      batch.update(submissionRef, {
        status: isCorrect ? "correct" : "incorrect",
        isCorrect,
        pointsAwarded,
        newTotalScore: newScore,
        feedback: isCorrect ? "Great job!" : "Incorrect answer. Keep trying!",
      });

      // Update session
      const sessionRef = db.collection("sessions").doc(submission.sessionId);
      batch.update(sessionRef, {
        score: newScore,
        totalAnswered: newTotalAnswered,
        correctAnswers: newCorrectAnswers,
        completedChallengeIds: newCompletedIds,
        currentDifficulty: newDifficulty,
        activeChallengeId: null,
      });

      await batch.commit();

      // Update real-time leaderboard
      await rtdb.ref(`leaderboard/${session.teamId}`).update({
        score: newScore,
        completedCount: newCompletedIds.length,
        lastUpdated: Date.now(),
      });

      return null;
    } catch (error) {
      console.error("Validation error:", error);
      return submissionRef.update({ status: "error", feedback: "Server error" });
    }
  });

// ══════════════════════════════════════════
// 2. AUTO-EXPIRE SESSIONS
// Runs every 5 minutes to check for expired sessions
// ══════════════════════════════════════════
exports.autoExpireSessions = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const expiredSessions = await db
      .collection("sessions")
      .where("isActive", "==", true)
      .where("endTime", "<=", now)
      .get();

    const batch = db.batch();
    const promises = [];

    expiredSessions.forEach((doc) => {
      const session = doc.data();
      batch.update(doc.ref, { isActive: false });

      // Clean up realtime DB
      promises.push(rtdb.ref(`active_timers/${session.teamId}`).remove());

      // Mark leaderboard entry as inactive
      promises.push(
        rtdb.ref(`leaderboard/${session.teamId}`).update({ isActive: false })
      );
    });

    if (!expiredSessions.empty) {
      await batch.commit();
      await Promise.all(promises);
      console.log(`Expired ${expiredSessions.size} sessions`);
    }

    return null;
  });

// ══════════════════════════════════════════
// 3. RATE LIMITING
// Prevents rapid-fire submissions (anti-cheat)
// ══════════════════════════════════════════
exports.rateLimitSubmissions = functions.firestore
  .document("submissions/{submissionId}")
  .onCreate(async (snap, context) => {
    const submission = snap.data();
    const sessionId = submission.sessionId;

    // Check recent submissions (last 10 seconds)
    const tenSecondsAgo = new Date(Date.now() - 10000);
    const recentSubmissions = await db
      .collection("submissions")
      .where("sessionId", "==", sessionId)
      .where("submittedAt", ">=", admin.firestore.Timestamp.fromDate(tenSecondsAgo))
      .get();

    if (recentSubmissions.size > 3) {
      // More than 3 submissions in 10 seconds — suspicious
      console.warn(`Rate limit exceeded for session: ${sessionId}`);
      return snap.ref.update({
        status: "rejected",
        feedback: "Too many submissions. Please slow down.",
      });
    }

    return null;
  });

// ══════════════════════════════════════════
// HELPER: Progressive Difficulty Calculator
// ══════════════════════════════════════════
function calculateDifficulty(score, accuracyRate) {
  let baseDifficulty;
  if (score < 50) baseDifficulty = "easy";
  else if (score < 150) baseDifficulty = "medium";
  else if (score < 300) baseDifficulty = "hard";
  else baseDifficulty = "expert";

  // Accuracy boost
  if (accuracyRate > 0.8) {
    baseDifficulty = bumpUp(baseDifficulty);
  }
  // Accuracy penalty
  if (accuracyRate < 0.4) {
    baseDifficulty = bumpDown(baseDifficulty);
  }

  return baseDifficulty;
}

function bumpUp(d) {
  const order = ["easy", "medium", "hard", "expert"];
  const idx = order.indexOf(d);
  return order[Math.min(idx + 1, order.length - 1)];
}

function bumpDown(d) {
  const order = ["easy", "medium", "hard", "expert"];
  const idx = order.indexOf(d);
  return order[Math.max(idx - 1, 0)];
}

