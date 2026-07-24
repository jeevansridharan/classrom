// functions/verify_similarity.js
const fs = require('fs');
const path = require('path');

// Read index.js content to extract similarity functions
const indexJsContent = fs.readFileSync(path.join(__dirname, 'index.js'), 'utf8');

// Simple extraction / regex of the functions or we can define them here
// Let's copy the tokenization, idf, tfidfVector, and cosineSimilarity logic
// directly from index.js to run it safely in isolation.

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

// Mock database questions
const databaseQuestions = [
  { id: '1', title: 'How to solve linear differential equations?', body: 'I am struggling with linear equations of first order.' },
  { id: '2', title: 'What is database normalization and 3NF?', body: 'Explain database tables normalization, first second and third normal forms.' },
  { id: '3', title: 'Binary search tree traversal implementation', body: 'How to implement inorder, preorder and postorder traversals in Python.' },
  { id: '4', title: 'Understanding thermodynamics first law', body: 'Need clear explanation of conservation of energy in thermal systems.' },
];

function checkDuplicate(newTitle, newBody) {
  console.log(`\nChecking duplicate for:\nTitle: "${newTitle}"\nBody: "${newBody}"\n`);
  
  const inputText = `${newTitle} ${newBody || ''}`;
  const inputTokens = tokenize(inputText);

  const corpus = databaseQuestions.map((c) => tokenize(`${c.title} ${c.body}`));
  const allDocs = [...corpus, inputTokens];
  const idf = computeIdf(allDocs);

  const inputVec = tfidfVector(inputTokens, idf);

  const scored = databaseQuestions.map((c, i) => {
    const docVec = tfidfVector(corpus[i], idf);
    const score = cosineSimilarity(inputVec, docVec);
    return { ...c, score };
  });

  const THRESHOLD = 0.35;
  const suggestions = scored
    .filter((c) => c.score >= THRESHOLD)
    .sort((a, b) => b.score - a.score);

  if (suggestions.length === 0) {
    console.log('✅ No duplicate questions detected.');
  } else {
    console.log('⚠️ Potentially duplicate questions detected:');
    suggestions.forEach((s) => {
      console.log(`- [Match: ${(s.score * 100).toFixed(1)}%] Title: "${s.title}" (ID: ${s.id})`);
    });
  }
}

// Run test cases
checkDuplicate(
  'How do I solve first order linear differential equations?',
  'Looking for methods to solve linear differential equations step by step.'
);

checkDuplicate(
  'Explain 3NF normalization in DBMS',
  'What are the normal forms like 1NF, 2NF and 3NF in database management systems?'
);

checkDuplicate(
  'Write simple sorting algorithms in C++',
  'Bubble sort, quick sort and merge sort implementation'
);
