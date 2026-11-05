import { describe, it, before, after, beforeEach } from 'node:test';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, Timestamp, serverTimestamp,
} from 'firebase/firestore';
import { makeEnv, as, seedIncident, validCreate, T0 } from './helpers.mjs';

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

describe('users', () => {
  it('create own with role student OK', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertSucceeds(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('amani@alustudent.com')));
  });
  // Regression: sign-up writes the profile BEFORE the email is verified.
  it('create with role staff refused', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('amani@alustudent.com', { role: 'staff' })));
  });
  it('student reads own doc OK', async () => {
    await assertSucceeds(getDoc(doc(dbOf('stu1'), 'users/stu1')));
  });
  it('student reading another users doc refused', async () => {
    await assertFails(getDoc(doc(dbOf('stu1'), 'users/stu2')));
  });
});

describe('incident reads', () => {
  beforeEach(() => seed());
  it('verified student OK', async () => { await assertSucceeds(getDoc(inc(dbOf('stu2')))); });
  it('unverified refused', async () => { await assertFails(getDoc(inc(dbOf('unv')))); });
  it('non-ALU refused', async () => { await assertFails(getDoc(inc(dbOf('out')))); });
});

describe('incident create', () => {
  const create = (over, who = 'stu1', uid = 'stu1') => setDoc(inc(dbOf(who), 'new1'), validCreate(uid, over));
  // Regression: the filing entry never carries the reporter's name, so hiding it later cannot leak.
  it('create with the reporter name in history refused', async () => {
    await assertFails(create({ history: [{ status: 'submitted', note: 'Filed', byName: 'Amani', at: Timestamp.now() }] }));
  });
  it('valid create OK', async () => { await assertSucceeds(create({})); });
  it('reporterId of someone else refused', async () => { await assertFails(create({ reporterId: 'stu2' })); });
});

describe('owner edit', () => {
  const edit = (who, fields) => updateDoc(inc(dbOf(who)), { ...fields, updatedAt: serverTimestamp() });
  it('description while submitted OK', async () => {
    await seed();
    await assertSucceeds(edit('stu1', { description: 'The tap in the block B kitchen is fully broken now.' }));
  });
  it('description after acknowledged refused', async () => {
    await seed({ status: 'acknowledged' });
    await assertFails(edit('stu1', { description: 'The tap in the block B kitchen is fully broken now.' }));
  });
});

describe('status change', () => {
  const change = (who, to, over = {}, base = oldHistory) => updateDoc(inc(dbOf(who)), {
    status: to,
    history: [...base, entry(to)],
    updatedAt: serverTimestamp(),
    ...over,
  });
  it('staff submitted -> in_progress with note OK', async () => {
    await seed();
    await assertSucceeds(change('staff1', 'in_progress'));
  });
  it('staff submitted -> resolved refused', async () => {
    await seed();
    await assertFails(change('staff1', 'resolved'));
  });
  it('student (owner) status change refused', async () => {
    await seed();
    await assertFails(change('stu1', 'in_progress'));
  });
});

describe('affects me too', () => {
  const set = (who, list, extra = {}) => updateDoc(inc(dbOf(who)), { affectedBy: list, ...extra });
  it('stu2 adding own uid OK', async () => {
    await seed();
    await assertSucceeds(set('stu2', ['stu2']));
  });
  it('stu2 adding someone elses uid refused', async () => {
    await seed();
    await assertFails(set('stu2', ['stu3']));
  });
});

describe('incident delete', () => {
  it('owner while submitted OK', async () => {
    await seed();
    await assertSucceeds(deleteDoc(inc(dbOf('stu1'))));
  });
  it('other student refused', async () => {
    await seed();
    await assertFails(deleteDoc(inc(dbOf('stu2'))));
  });
  it('non-ALU refused', async () => {
    await seed({ reporterId: 'out' });
    await assertFails(deleteDoc(inc(dbOf('out'))));
  });
});

describe('profile edit', () => {
  const upd = (who, data, uid = who) => updateDoc(doc(dbOf(who), `users/${uid}`), data);
  it('owner sets displayName and programme OK', async () => {
    await assertSucceeds(upd('stu1', { displayName: 'Amani K', programme: 'BSc Software Engineering' }));
  });
  it('owner sets programme Wizardry refused', async () => {
    await assertFails(upd('stu1', { programme: 'Wizardry' }));
  });
});

describe('todos stay open', () => {
  it('unauthenticated can write and read', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertSucceeds(setDoc(doc(db, 'todos/t1'), { title: 'x', done: false }));
    await assertSucceeds(getDoc(doc(db, 'todos/t1')));
  });
});

