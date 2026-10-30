const { readFileSync } = require('node:fs');
const { test, before, after } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, serverTimestamp } = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-mechanica', firestore: { host: '127.0.0.1', port: 8080, rules: readFileSync('../../firestore.rules', 'utf8') } }); });
after(async () => { await env?.cleanup(); });
function db(uid) { return uid ? env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore() : env.unauthenticatedContext().firestore(); }
function profile(uid) { return { displayName: 'Người gác máy', email: `${uid}@example.com`, createdAt: serverTimestamp(), lastPlayedAt: serverTimestamp(), tutorialCompleted: false, schemaVersion: 3 }; }
function result(stars = 3) { return { completed: true, bestStars: stars, bestMoves: 12, bestTimeSeconds: 30, attempts: 1, lastCompletedAt: serverTimestamp() }; }
test('owner creates and reads profile; strangers and anonymous cannot read or write', async () => {
 await assertSucceeds(setDoc(doc(db('owner'), 'users/owner'), profile('owner')));
 await assertSucceeds(getDoc(doc(db('owner'), 'users/owner')));
 await assertFails(getDoc(doc(db('other'), 'users/owner')));
 await assertFails(getDoc(doc(db(), 'users/owner')));
 await assertFails(setDoc(doc(db('other'), 'users/owner'), profile('other')));
});
test('profile rejects passwords, wrong email and invalid name type', async () => {
 await assertFails(setDoc(doc(db('password'), 'users/password'), { ...profile('password'), password: 'must-not-store' }));
 await assertFails(setDoc(doc(db('wrongemail'), 'users/wrongemail'), profile('other')));
 await assertFails(setDoc(doc(db('wrongtype'), 'users/wrongtype'), { ...profile('wrongtype'), displayName: 42 }));
});
test('profile updates timestamp and tutorial completion without resetting true', async () => {
 const ref = doc(db('tutorial'), 'users/tutorial');
 await assertSucceeds(setDoc(ref, profile('tutorial')));
 await assertSucceeds(updateDoc(ref, { tutorialCompleted: true, lastPlayedAt: serverTimestamp() }));
 await assertFails(updateDoc(ref, { tutorialCompleted: false, lastPlayedAt: serverTimestamp() }));
});
test('progress validates level range, fields and monotonic unlock', async () => {
 const ref = doc(db('progress'), 'users/progress/progress/current');
 const p = { unlockedLevel: 4, currentLevel: 'LV04', completedLevels: ['LV01'], lastSavedAt: serverTimestamp(), saveVersion: 3 };
 await assertSucceeds(setDoc(ref, p));
 await assertFails(setDoc(ref, { ...p, unlockedLevel: 13 }));
 await assertFails(setDoc(ref, { ...p, unlockedLevel: 2 }));
 await assertFails(setDoc(ref, { ...p, currentLevel: 'LV99' }));
 await assertFails(setDoc(ref, { ...p, completedLevels: ['LV99'] }));
 await assertFails(setDoc(ref, { ...p, completedLevels: [] }));
});
test('result limits stars and level IDs, preserves better achievements', async () => {
 const ref = doc(db('score'), 'users/score/levelResults/LV01');
 await assertSucceeds(setDoc(ref, result()));
 await assertFails(setDoc(ref, { ...result(2), attempts: 2 }));
 await assertFails(setDoc(doc(db('score'), 'users/score/levelResults/LV02'), result(4)));
 await assertFails(setDoc(doc(db('score'), 'users/score/levelResults/LV00'), result()));
 await assertSucceeds(setDoc(ref, { ...result(), attempts: 2, bestMoves: 10 }));
 await assertFails(getDoc(doc(db('other'), 'users/score/levelResults/LV01')));
});
test('idempotency receipt is create-only and owner-private', async () => {
 const ref = doc(db('receipt'), 'users/receipt/syncEvents/run_1');
 const data = { kind: 'result', createdAt: serverTimestamp() };
 await assertSucceeds(setDoc(ref, data));
 await assertFails(setDoc(ref, data));
 await assertFails(getDoc(doc(db('other'), 'users/receipt/syncEvents/run_1')));
});
