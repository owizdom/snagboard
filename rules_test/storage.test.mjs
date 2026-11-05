import { describe, it, before, after, beforeEach } from 'node:test';
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { ref, uploadBytes } from 'firebase/storage';
import { makeEnv, as } from './helpers.mjs';

let env;
before(async () => { env = await makeEnv('storage'); });
after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearStorage(); });

const small = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
const jpeg = { contentType: 'image/jpeg' };
const st = (who) => as(env, who).storage();

describe('photo upload', () => {
  it('own folder image/jpeg under 5 MB OK', async () => {
    await assertSucceeds(uploadBytes(ref(st('stu1'), 'incident_photos/stu1/1.jpg'), small, jpeg));
  });
  it('another uids folder refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'incident_photos/stu2/1.jpg'), small, jpeg));
  });
  it('6 MB refused', async () => {
    await assertFails(uploadBytes(ref(st('stu1'), 'incident_photos/stu1/big.jpg'), new Uint8Array(6 * 1024 * 1024), jpeg));
  });
});

describe('avatars', () => {
  it('own folder image/jpeg small OK', async () => {
    await assertSucceeds(uploadBytes(ref(st('stu1'), 'avatars/stu1/1.jpg'), small, jpeg));
  });
});
