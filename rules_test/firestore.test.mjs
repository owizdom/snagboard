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
  it('create with role staff refused', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('amani@alustudent.com', { role: 'staff' })));
  });
  it('create with someone elses email refused', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('kofi@alustudent.com')));
  });
  it('create with extra key refused', async () => {
    await env.withSecurityRulesDisabled((c) => deleteDoc(doc(c.firestore(), 'users/stu1')));
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/stu1'), newUser('amani@alustudent.com', { extra: 1 })));
  });
  it('create doc for another uid refused', async () => {
    await assertFails(setDoc(doc(dbOf('stu1'), 'users/zzz'), newUser('amani@alustudent.com')));
  });
  it('student updating own role refused', async () => {
    await assertFails(updateDoc(doc(dbOf('stu1'), 'users/stu1'), { role: 'staff' }));
  });
  it('staff updating own role refused', async () => {
    await assertFails(updateDoc(doc(dbOf('staff1'), 'users/staff1'), { role: 'student' }));
  });
  it('displayName change by owner OK', async () => {
    await assertSucceeds(updateDoc(doc(dbOf('stu1'), 'users/stu1'), { displayName: 'Amani K' }));
  });
  it('displayName change by another student refused', async () => {
    await assertFails(updateDoc(doc(dbOf('stu2'), 'users/stu1'), { displayName: 'Hacked' }));
  });
  it('student reads own doc OK', async () => {
    await assertSucceeds(getDoc(doc(dbOf('stu1'), 'users/stu1')));
  });
  it('student reading another users doc refused', async () => {
    await assertFails(getDoc(doc(dbOf('stu1'), 'users/stu2')));
  });
  it('staff reading a student doc OK', async () => {
    await assertSucceeds(getDoc(doc(dbOf('staff1'), 'users/stu1')));
  });
  it('unverified reading own doc refused', async () => {
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), 'users/unv'), { displayName: 'U', email: 'new@alustudent.com', role: 'student', createdAt: T0 }));
    await assertFails(getDoc(doc(dbOf('unv'), 'users/unv')));
  });
});

describe('incident reads', () => {
  beforeEach(() => seed());
  it('verified student OK', async () => { await assertSucceeds(getDoc(inc(dbOf('stu2')))); });
  it('staff OK', async () => { await assertSucceeds(getDoc(inc(dbOf('staff1')))); });
  it('plus-addressed ALU OK', async () => { await assertSucceeds(getDoc(inc(dbOf('plus')))); });
  it('unverified refused', async () => { await assertFails(getDoc(inc(dbOf('unv')))); });
  it('non-ALU refused', async () => { await assertFails(getDoc(inc(dbOf('out')))); });
  it('unauthenticated refused', async () => {
    await assertFails(getDoc(inc(env.unauthenticatedContext().firestore())));
  });
});

describe('incident create', () => {
  const create = (over, who = 'stu1', uid = 'stu1') => setDoc(inc(dbOf(who), 'new1'), validCreate(uid, over));
  it('valid create OK', async () => { await assertSucceeds(create({})); });
  it('valid anonymous create OK', async () => { await assertSucceeds(create({ anonymous: true, reporterName: null })); });
  it('valid create with photo in own folder OK', async () => {
    await assertSucceeds(create({ photoUrl: 'https://x/y', photoPath: 'incident_photos/stu1/1.jpg' }));
  });
  it('valid create with spot OK', async () => { await assertSucceeds(create({ spot: 'Room 12' })); });
  it('status resolved refused', async () => { await assertFails(create({ status: 'resolved', history: [entry('resolved', 'x ok', 'A')] })); });
  it('history first entry not submitted refused', async () => {
    await assertFails(create({ history: [entry('acknowledged', 'Filed', 'A')] }));
  });
  it('reporterId of someone else refused', async () => { await assertFails(create({ reporterId: 'stu2' })); });
  it('invalid category refused', async () => { await assertFails(create({ category: 'plumbing' })); });
  it('invalid urgency refused', async () => { await assertFails(create({ urgency: 'asap' })); });
  it('title of 4 chars refused', async () => { await assertFails(create({ title: 'abcd' })); });
  it('title of 5 chars OK', async () => { await assertSucceeds(create({ title: 'abcde' })); });
  it('title of 80 chars OK', async () => { await assertSucceeds(create({ title: 'a'.repeat(80) })); });
  it('title of 81 chars refused', async () => { await assertFails(create({ title: 'a'.repeat(81) })); });
  it('description of 14 chars refused', async () => { await assertFails(create({ description: 'a'.repeat(14) })); });
  it('empty location refused', async () => { await assertFails(create({ location: '' })); });
  it('non-empty affectedBy refused', async () => { await assertFails(create({ affectedBy: ['stu2'] })); });
  it('anonymous true with reporterName refused', async () => { await assertFails(create({ anonymous: true, reporterName: 'Amani' })); });
  it('not anonymous with null reporterName refused', async () => { await assertFails(create({ anonymous: false, reporterName: null })); });
  it('history of 2 entries refused', async () => {
    await assertFails(create({ history: [entry('submitted', 'Filed', 'A'), entry('submitted', 'Again', 'A')] }));
  });
  it('photoPath in another uids folder refused', async () => {
    await assertFails(create({ photoUrl: 'https://x/y', photoPath: 'incident_photos/stu2/1.jpg' }));
  });
  it('photoUrl without photoPath refused', async () => {
    await assertFails(create({ photoUrl: 'https://x/y', photoPath: null }));
  });
  it('client timestamp instead of server time refused', async () => {
    await assertFails(create({ createdAt: Timestamp.fromMillis(1000) }));
  });
  it('extra key refused', async () => { await assertFails(create({ extra: true })); });
  it('unverified user refused', async () => { await assertFails(create({}, 'unv', 'unv')); });
  it('non-ALU user refused', async () => { await assertFails(create({}, 'out', 'out')); });
});

describe('owner edit', () => {
  const edit = (who, fields) => updateDoc(inc(dbOf(who)), { ...fields, updatedAt: serverTimestamp() });
  it('description while submitted OK', async () => {
    await seed();
    await assertSucceeds(edit('stu1', { description: 'The tap in the block B kitchen is fully broken now.' }));
  });
  it('make anonymous while submitted OK', async () => {
    await seed();
    await assertSucceeds(edit('stu1', { anonymous: true, reporterName: null }));
  });
  it('description after acknowledged refused', async () => {
    await seed({ status: 'acknowledged' });
    await assertFails(edit('stu1', { description: 'The tap in the block B kitchen is fully broken now.' }));
  });
  it('owner editing status refused', async () => {
    await seed();
    await assertFails(edit('stu1', { status: 'resolved' }));
  });
  it('owner editing history refused', async () => {
    await seed();
    await assertFails(edit('stu1', { history: [] }));
  });
  it('owner editing reporterId refused', async () => {
    await seed();
    await assertFails(edit('stu1', { reporterId: 'stu2' }));
  });
  it('owner edit with title too short refused', async () => {
    await seed();
    await assertFails(edit('stu1', { title: 'abcd' }));
  });
  it('other student editing refused', async () => {
    await seed();
    await assertFails(edit('stu2', { description: 'The tap in the block B kitchen is fully broken now.' }));
  });
  it('staff editing title refused', async () => {
    await seed();
    await assertFails(edit('staff1', { title: 'Staff renamed this' }));
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
  it('staff submitted -> acknowledged OK', async () => {
    await seed();
    await assertSucceeds(change('staff1', 'acknowledged'));
  });
  it('staff in_progress -> resolved OK', async () => {
    await seed({ status: 'in_progress' });
    await assertSucceeds(change('staff1', 'resolved'));
  });
  it('staff resolved -> in_progress (reopen) OK', async () => {
    await seed({ status: 'resolved' });
    await assertSucceeds(change('staff1', 'in_progress'));
  });
  it('staff declined -> acknowledged (reopen) OK', async () => {
    await seed({ status: 'declined' });
    await assertSucceeds(change('staff1', 'acknowledged'));
  });
  it('staff submitted -> resolved refused', async () => {
    await seed();
    await assertFails(change('staff1', 'resolved'));
  });
  it('staff acknowledged -> resolved refused', async () => {
    await seed({ status: 'acknowledged' });
    await assertFails(change('staff1', 'resolved'));
  });
  it('staff same status -> same status refused', async () => {
    await seed();
    await assertFails(change('staff1', 'submitted'));
  });
  it('staff appended entry status mismatch refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), {
      status: 'in_progress',
      history: [...oldHistory, entry('acknowledged')],
      updatedAt: serverTimestamp(),
    }));
  });
  it('staff rewriting an earlier history entry refused', async () => {
    await seed();
    const rewritten = [{ ...oldHistory[0], note: 'Tampered' }, entry('in_progress')];
    await assertFails(updateDoc(inc(dbOf('staff1')), { status: 'in_progress', history: rewritten, updatedAt: serverTimestamp() }));
  });
  it('staff dropping earlier entry while appending refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), { status: 'in_progress', history: [entry('in_progress')], updatedAt: serverTimestamp() }));
  });
  it('staff appending two entries refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), {
      status: 'in_progress', history: [...oldHistory, entry('acknowledged'), entry('in_progress')], updatedAt: serverTimestamp(),
    }));
  });
  it('staff status change without history append refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), { status: 'in_progress', updatedAt: serverTimestamp() }));
  });
  it('staff note of 2 chars refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), {
      status: 'in_progress', history: [...oldHistory, entry('in_progress', 'ab')], updatedAt: serverTimestamp(),
    }));
  });
  it('staff note of 3 chars OK', async () => {
    await seed();
    await assertSucceeds(updateDoc(inc(dbOf('staff1')), {
      status: 'in_progress', history: [...oldHistory, entry('in_progress', 'abc')], updatedAt: serverTimestamp(),
    }));
  });
  it('staff note of 281 chars refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(dbOf('staff1')), {
      status: 'in_progress', history: [...oldHistory, entry('in_progress', 'a'.repeat(281))], updatedAt: serverTimestamp(),
    }));
  });
  it('staff status change also changing title refused', async () => {
    await seed();
    await assertFails(change('staff1', 'in_progress', { title: 'Sneaky rename' }));
  });
  it('student (owner) status change refused', async () => {
    await seed();
    await assertFails(change('stu1', 'in_progress'));
  });
  it('other student status change refused', async () => {
    await seed();
    await assertFails(change('stu2', 'in_progress'));
  });
  it('unverified staff-claim account refused', async () => {
    await seed();
    await env.withSecurityRulesDisabled((c) => setDoc(doc(c.firestore(), 'users/unv'), { displayName: 'U', email: 'new@alustudent.com', role: 'staff', createdAt: T0 }));
    await assertFails(change('unv', 'in_progress'));
  });
});

describe('affects me too', () => {
  const set = (who, list, extra = {}) => updateDoc(inc(dbOf(who)), { affectedBy: list, ...extra });
  it('stu2 adding own uid OK', async () => {
    await seed();
    await assertSucceeds(set('stu2', ['stu2']));
  });
  it('stu2 adding own uid next to existing uids OK', async () => {
    await seed({ affectedBy: ['stu3'] });
    await assertSucceeds(set('stu2', ['stu3', 'stu2']));
  });
  it('stu2 removing own uid OK', async () => {
    await seed({ affectedBy: ['stu2'] });
    await assertSucceeds(set('stu2', []));
  });
  it('staff adding own uid OK', async () => {
    await seed();
    await assertSucceeds(set('staff1', ['staff1']));
  });
  it('stu2 adding someone elses uid refused', async () => {
    await seed();
    await assertFails(set('stu2', ['stu3']));
  });
  it('stu2 removing someone elses uid refused', async () => {
    await seed({ affectedBy: ['stu3'] });
    await assertFails(set('stu2', []));
  });
  it('stu2 adding two uids refused', async () => {
    await seed();
    await assertFails(set('stu2', ['stu2', 'stu3']));
  });
  it('stu2 adding own uid while changing title refused', async () => {
    await seed();
    await assertFails(set('stu2', ['stu2'], { title: 'Changed by stu2' }));
  });
  it('stu2 adding own uid while changing status refused', async () => {
    await seed();
    await assertFails(set('stu2', ['stu2'], { status: 'resolved' }));
  });
  it('unverified adding own uid refused', async () => {
    await seed();
    await assertFails(set('unv', ['unv']));
  });
  it('unauthenticated adding refused', async () => {
    await seed();
    await assertFails(updateDoc(inc(env.unauthenticatedContext().firestore()), { affectedBy: ['x'] }));
  });
});

describe('incident delete', () => {
  it('owner while submitted OK', async () => {
    await seed();
    await assertSucceeds(deleteDoc(inc(dbOf('stu1'))));
  });
  it('owner after acknowledged refused', async () => {
    await seed({ status: 'acknowledged' });
    await assertFails(deleteDoc(inc(dbOf('stu1'))));
  });
  it('other student refused', async () => {
    await seed();
    await assertFails(deleteDoc(inc(dbOf('stu2'))));
  });
  it('staff while submitted OK', async () => {
    await seed();
    await assertSucceeds(deleteDoc(inc(dbOf('staff1'))));
  });
  it('staff after resolved OK', async () => {
    await seed({ status: 'resolved' });
    await assertSucceeds(deleteDoc(inc(dbOf('staff1'))));
  });
  it('unauthenticated refused', async () => {
    await seed();
    await assertFails(deleteDoc(inc(env.unauthenticatedContext().firestore())));
  });
  it('non-ALU refused', async () => {
    await seed({ reporterId: 'out' });
    await assertFails(deleteDoc(inc(dbOf('out'))));
  });
});

describe('todos stay open', () => {
  it('unauthenticated can write and read', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertSucceeds(setDoc(doc(db, 'todos/t1'), { title: 'x', done: false }));
    await assertSucceeds(getDoc(doc(db, 'todos/t1')));
  });
});

describe('everything else is closed', () => {
  it('unknown collection refused even for staff', async () => {
    await assertFails(setDoc(doc(dbOf('staff1'), 'other/x'), { a: 1 }));
  });
});
