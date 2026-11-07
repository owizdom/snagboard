// Security rules tests. Run: cd rules_test && npm install && npm test
import { describe, it, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, Timestamp, serverTimestamp } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const rules = (f) => readFileSync(resolve(here, '..', f), 'utf8');

async function makeEnv(which) {
  const cfg = { projectId: 'demo-snagboard' };
  if (which === 'firestore') cfg.firestore = { rules: rules('firestore.rules'), host: '127.0.0.1', port: 8080 };
  return initializeTestEnvironment(cfg);
}

const ids = {
  stu1: { uid: 'stu1', claims: { email: 'amani@alustudent.com', email_verified: true } },
  stu2: { uid: 'stu2', claims: { email: 'kofi@alustudent.com', email_verified: true } },
  staff1: { uid: 'staff1', claims: { email: 'desk@alueducation.com', email_verified: true } },
  unv: { uid: 'unv', claims: { email: 'new@alustudent.com', email_verified: false } },
  out: { uid: 'out', claims: { email: 'x@gmail.com', email_verified: true } },
};

const as = (env, who) => env.authenticatedContext(ids[who].uid, ids[who].claims);

const T0 = Timestamp.fromMillis(1700000000000);

// Seeded (rules-disabled) incident, Timestamp values allowed.
function seedIncident(over = {}) {
  return {
    title: 'Broken tap in block B',
    description: 'The tap in the block B kitchen leaks all day.',
    category: 'water',
    location: 'Block B',
    spot: null,
    urgency: 'normal',
    status: 'submitted',
    photoUrl: null,
    photoPath: null,
    reporterId: 'stu1',
    reporterName: 'Amani',
    anonymous: false,
    affectedBy: [],
    history: [{ status: 'submitted', note: 'Filed', byName: 'Amani', at: T0 }],
    createdAt: T0,
    updatedAt: T0,
    ...over,
  };
}

// Client-built valid create payload per amendment A1.
function validCreate(uid = 'stu1', over = {}) {
  return {
    title: 'Broken tap in block B',
    description: 'The tap in the block B kitchen leaks all day.',
    category: 'water',
    location: 'Block B',
    spot: null,
    urgency: 'normal',
    status: 'submitted',
    photoUrl: null,
    photoPath: null,
    reporterId: uid,
    reporterName: 'Amani',
    anonymous: false,
    affectedBy: [],
    history: [{ status: 'submitted', note: 'Filed', byName: 'Reporter', at: Timestamp.now() }],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...over,
  };
}

let env;
before(async () => { env = await makeEnv('firestore'); });
after(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/staff1'), { displayName: 'Desk', email: 'desk@alueducation.com', role: 'staff', createdAt: T0 });
    await setDoc(doc(db, 'users/stu1'), { displayName: 'Amani', email: 'amani@alustudent.com', role: 'student', createdAt: T0 });
    await setDoc(doc(db, 'users/stu2'), { displayName: 'Kofi', email: 'kofi@alustudent.com', role: 'student', createdAt: T0 });
  });
});

const seed = (over = {}, id = 'inc1') =>
  env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), `incidents/${id}`), seedIncident(over)));
const dbOf = (who) => as(env, who).firestore();
const inc = (db, id = 'inc1') => doc(db, `incidents/${id}`);
const newUser = (email, over = {}) => ({ displayName: 'Amani', email, role: 'student', createdAt: serverTimestamp(), ...over });
const entry = (status, note = 'Looking into it', byName = 'Desk') => ({ status, note, byName, at: Timestamp.now() });
const oldHistory = seedIncident().history;

describe('sign-up', () => {
  it('an alueducation.com address signs up as staff', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/staff1')));
    await assertSucceeds(setDoc(doc(dbOf('staff1'), 'users/staff1'), newUser('desk@alueducation.com', { role: 'staff' })));
  });
  it('a student cannot sign up as staff', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('amani@alustudent.com', { role: 'staff' })));
  });
});

describe('reading snags', () => {
  beforeEach(() => seed());
  it('a verified ALU student can read', async () => { await assertSucceeds(getDoc(inc(dbOf('stu2')))); });
  it('an unverified account cannot read', async () => { await assertFails(getDoc(inc(dbOf('unv')))); });
  it('a non-ALU account cannot read', async () => { await assertFails(getDoc(inc(dbOf('out')))); });
});

describe('filing a snag', () => {
  it('a student can file a valid snag', async () => {
    await assertSucceeds(setDoc(inc(dbOf('stu1'), 'new1'), validCreate('stu1', {})));
  });
});

describe('changing status', () => {
  const change = (who, to) => updateDoc(inc(dbOf(who)), {
    status: to,
    history: [...oldHistory, entry(to)],
    updatedAt: serverTimestamp(),
  });
  beforeEach(() => seed());
  it('staff can move submitted to in progress with a note', async () => { await assertSucceeds(change('staff1', 'in_progress')); });
  it('staff cannot skip straight to resolved', async () => { await assertFails(change('staff1', 'resolved')); });
  it('a student cannot change a status', async () => { await assertFails(change('stu1', 'in_progress')); });
});
