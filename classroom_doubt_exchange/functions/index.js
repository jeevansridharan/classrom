// functions/index.js
// Cloud Functions for Classroom Doubt Exchange
// Deploy with: firebase deploy --only functions

const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

// ══════════════════════════════════════════════════════════════════════════════
// 1. onVote — Triggered when a vote is written on a question or answer
//    Updates voteCount on the parent document and awards reputation.
// ══════════════════════════════════════════════════════════════════════════════
exports.onQuestionVote = onDocumentWritten(
  'questions/{questionId}/votes/{voterUid}',
  async (event) => {
    const { questionId, voterUid } = event.params;

    const before = event.data.before?.data();
    const after = event.data.after?.data();

    const prevValue = before?.value ?? 0;
    const newValue = after?.value ?? 0;
    const delta = newValue - prevValue;

    if (delta === 0) return;

    const questionRef = db.collection('questions').doc(questionId);

    await db.runTransaction(async (tx) => {
      const questionSnap = await tx.get(questionRef);
      if (!questionSnap.exists) return;

      const authorUid = questionSnap.data()?.authorUid;

      // Update vote count
      tx.update(questionRef, { voteCount: FieldValue.increment(delta) });

      // Update author reputation (10 per upvote, -2 per downvote)
      if (authorUid && authorUid !== voterUid) {
        const repDelta = delta > 0 ? delta * 10 : delta * 2;
        tx.update(db.collection('users').doc(authorUid), {
          reputationPoints: FieldValue.increment(repDelta),
        });
      }
    });
  }
);

exports.onAnswerVote = onDocumentWritten(
  'answers/{answerId}/votes/{voterUid}',
  async (event) => {
    const { answerId, voterUid } = event.params;

    const before = event.data.before?.data();
    const after = event.data.after?.data();

    const prevValue = before?.value ?? 0;
    const newValue = after?.value ?? 0;
    const delta = newValue - prevValue;

    if (delta === 0) return;

    const answerRef = db.collection('answers').doc(answerId);

    await db.runTransaction(async (tx) => {
      const answerSnap = await tx.get(answerRef);
      if (!answerSnap.exists) return;

      const authorUid = answerSnap.data()?.authorUid;

      tx.update(answerRef, { voteCount: FieldValue.increment(delta) });

      if (authorUid && authorUid !== voterUid) {
        const repDelta = delta > 0 ? delta * 10 : delta * 2;
        tx.update(db.collection('users').doc(authorUid), {
          reputationPoints: FieldValue.increment(repDelta),
        });
      }
    });
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 2. onAnswerCreated — Updates answerCount on the parent question.
//    Also awards reputation to the question author for receiving an answer.
// ══════════════════════════════════════════════════════════════════════════════
exports.onAnswerCreated = onDocumentCreated(
  'answers/{answerId}',
  async (event) => {
    const answer = event.data.data();
    if (!answer?.questionId) return;

    await db.collection('questions').doc(answer.questionId).update({
      answerCount: FieldValue.increment(1),
      updatedAt: new Date(),
    });
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 3. onAnswerAccepted — Awards extra reputation when an answer is accepted.
// ══════════════════════════════════════════════════════════════════════════════
exports.onAnswerUpdated = onDocumentWritten(
  'answers/{answerId}',
  async (event) => {
    const before = event.data.before?.data();
    const after = event.data.after?.data();

    if (!before || !after) return;

    // Detect isAccepted flip: false → true
    if (!before.isAccepted && after.isAccepted) {
      const authorUid = after.authorUid;
      if (authorUid) {
        await db.collection('users').doc(authorUid).update({
          reputationPoints: FieldValue.increment(25), // Bonus for accepted answer
        });
      }
    }

    // Detect un-accept: true → false (revoke bonus)
    if (before.isAccepted && !after.isAccepted) {
      const authorUid = after.authorUid;
      if (authorUid) {
        await db.collection('users').doc(authorUid).update({
          reputationPoints: FieldValue.increment(-25),
        });
      }
    }
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// 4. checkDuplicate (Callable) — TF-IDF cosine similarity duplicate detection
//    Called from the Flutter app before a question is posted.
//    Returns up to 3 similar question IDs and titles.
// ══════════════════════════════════════════════════════════════════════════════
exports.checkDuplicate = onCall(
  { maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { title, body } = request.data;
    if (!title || title.length < 10) {
      return { suggestions: [] };
    }

    const inputText = `${title} ${body || ''}`;
    const inputTokens = tokenize(inputText);

    // Fetch 100 recent questions
    const snap = await db
      .collection('questions')
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    if (snap.empty) return { suggestions: [] };

    const candidates = snap.docs.map((d) => ({
      id: d.id,
      title: d.data().title,
      body: d.data().body || '',
    }));

    const corpus = candidates.map((c) => tokenize(`${c.title} ${c.body}`));
    const allDocs = [...corpus, inputTokens];
    const idf = computeIdf(allDocs);

    const inputVec = tfidfVector(inputTokens, idf);

    const scored = candidates.map((c, i) => {
      const docVec = tfidfVector(corpus[i], idf);
      return {
        ...c,
        score: cosineSimilarity(inputVec, docVec),
      };
    });

    const THRESHOLD = 0.35;
    const suggestions = scored
      .filter((c) => c.score >= THRESHOLD)
      .sort((a, b) => b.score - a.score)
      .slice(0, 3)
      .map(({ id, title, score }) => ({ id, title, score }));

    return { suggestions };
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// NLP Utility functions
// ══════════════════════════════════════════════════════════════════════════════
const STOP_WORDS = new Set([
  'the','a','an','is','it','in','on','at','to','of','for','and','or','but',
  'with','how','what','why','when','where','do','i','my','can','be','this',
  'that','are','was','has','have','not','no','its','from','by','as','if','so','we',
]);

function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length >= 3 && !STOP_WORDS.has(w));
}

function computeIdf(corpus) {
  const docFreq = {};
  for (const doc of corpus) {
    const unique = new Set(doc);
    for (const term of unique) {
      docFreq[term] = (docFreq[term] || 0) + 1;
    }
  }
  const n = corpus.length;
  const idf = {};
  for (const [term, df] of Object.entries(docFreq)) {
    idf[term] = Math.log((n + 1) / (df + 1)) + 1;
  }
  return idf;
}

function tfidfVector(tokens, idf) {
  const tf = {};
  for (const token of tokens) {
    tf[token] = (tf[token] || 0) + 1;
  }
  const maxFreq = Math.max(...Object.values(tf), 1);
  const vec = {};
  for (const [term, freq] of Object.entries(tf)) {
    vec[term] = (freq / maxFreq) * (idf[term] || 1.0);
  }
  return vec;
}

function cosineSimilarity(a, b) {
  let dot = 0;
  for (const term of Object.keys(a)) {
    if (b[term]) dot += a[term] * b[term];
  }
  const magA = Math.sqrt(Object.values(a).reduce((s, v) => s + v * v, 0));
  const magB = Math.sqrt(Object.values(b).reduce((s, v) => s + v * v, 0));
  if (magA === 0 || magB === 0) return 0;
  return dot / (magA * magB);
}
