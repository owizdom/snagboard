import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { Timestamp, serverTimestamp } from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const rules = (f) => readFileSync(resolve(here, '..', f), 'utf8');

export async function makeEnv(which) {
  const cfg = { projectId: 'demo-snagboard' };
  if (which === 'firestore') cfg.firestore = { rules: rules('firestore.rules'), host: '127.0.0.1', port: 8080 };
  if (which === 'storage') cfg.storage = { rules: rules('storage.rules'), host: '127.0.0.1', port: 9199 };
  return initializeTestEnvironment(cfg);
}

export const ids = {
  stu1: { uid: 'stu1', claims: { email: 'amani@alustudent.com', email_verified: true } },
  stu2: { uid: 'stu2', claims: { email: 'kofi@alustudent.com', email_verified: true } },
  staff1: { uid: 'staff1', claims: { email: 'desk@alueducation.com', email_verified: true } },
  unv: { uid: 'unv', claims: { email: 'new@alustudent.com', email_verified: false } },
  out: { uid: 'out', claims: { email: 'x@gmail.com', email_verified: true } },
  plus: { uid: 'plus1', claims: { email: 'amani+staff@alustudent.com', email_verified: true } },
};

export const as = (env, who) => env.authenticatedContext(ids[who].uid, ids[who].claims);

export const T0 = Timestamp.fromMillis(1700000000000);

// Seeded (rules-disabled) incident, Timestamp values allowed.
export function seedIncident(over = {}) {
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
export function validCreate(uid = 'stu1', over = {}) {
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
    history: [{ status: 'submitted', note: 'Filed', byName: 'Amani', at: Timestamp.now() }],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...over,
  };
}
