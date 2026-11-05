import { describe, it, before, after, beforeEach } from 'node:test';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';
import { makeEnv, as } from './helpers.mjs';

let env;
before(async () => { env = await makeEnv('storage'); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearStorage(); });

const small = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const jpeg = { contentType: 'image/jpeg' };
const st = (who) => as(env, who).storage();
const seedPhoto = (path = 'incident_photos/stu1/seed.jpg') =>
  env.withSecurityRulesDisabled((c) => uploadBytes(ref(c.storage(), path), small, jpeg));

describe('photo upload', () => {
  it('own folder image/jpeg under 5 MB OK', async () => {
    await assertSucceeds(uploadBytes(ref(st('stu1'), 'incident_photos/stu1/1.jpg'), small, jpeg));
  });
  it('staff own folder OK', async () => {
    await assertSucceeds(uploadBytes(ref(st('staff1'), 'incident_photos/staff1/1.jpg'), small, jpeg));
  });
  it('another uids folder refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'incident_photos/stu2/1.jpg'), small, jpeg));
  });
  it('contentType text/plain refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'incident_photos/stu1/1.jpg'), small, { contentType: 'text/plain' }));
  });
  it('6 MB refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'incident_photos/stu1/big.jpg'), new Uint8Array(6 * 1024 * 1024), jpeg));
  });
  it('unverified upload refused', async () => {
    await assertFails(uploadBytes(ref(st('unv'), 'incident_photos/unv/1.jpg'), small, jpeg));
  });
  it('non-ALU upload refused', async () => {
    await assertFails(uploadBytes(ref(st('out'), 'incident_photos/out/1.jpg'), small, jpeg));
  });
  it('unauthenticated upload refused', async () => {
    await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), 'incident_photos/stu1/1.jpg'), small, jpeg));
  });
  it('path outside incident_photos refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'elsewhere/stu1/1.jpg'), small, jpeg));
  });
});

describe('photo read', () => {
  beforeEach(() => seedPhoto());
  it('verified student OK', async () => {
    await assertSucceeds(getBytes(ref(st('stu2'), 'incident_photos/stu1/seed.jpg')));
  });
  it('staff OK', async () => {
    await assertSucceeds(getBytes(ref(st('staff1'), 'incident_photos/stu1/seed.jpg')));
  });
  it('plus-addressed ALU OK', async () => {
    await assertSucceeds(getBytes(ref(st('plus'), 'incident_photos/stu1/seed.jpg')));
  });
  it('unauthenticated refused', async () => {
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), 'incident_photos/stu1/seed.jpg')));
  });
  it('unverified refused', async () => {
    await assertFails(getBytes(ref(st('unv'), 'incident_photos/stu1/seed.jpg')));
  });
  it('non-ALU refused', async () => {
    await assertFails(getBytes(ref(st('out'), 'incident_photos/stu1/seed.jpg')));
  });
});

describe('photo delete', () => {
  beforeEach(() => seedPhoto());
  it('owner OK', async () => {
    await assertSucceeds(deleteObject(ref(st('stu1'), 'incident_photos/stu1/seed.jpg')));
  });
  it('other student refused', async () => {
    await assertFails(deleteObject(ref(st('stu2'), 'incident_photos/stu1/seed.jpg')));
  });
  it('staff in someone elses folder refused', async () => {
    await assertFails(deleteObject(ref(st('staff1'), 'incident_photos/stu1/seed.jpg')));
  });
  it('unauthenticated refused', async () => {
    await assertFails(deleteObject(ref(env.unauthenticatedContext().storage(), 'incident_photos/stu1/seed.jpg')));
  });
});
