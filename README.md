# Snagboard

<img src="report/figures/logo.png" alt="Snagboard" width="320">

Campus incident reporting for ALU. A snag is anything on campus that needs fixing: a dry tap, a dead socket, a broken chair, a safety hazard. Students file a snag with an optional photo and follow it on a shared campus board. Staff move each snag along a fixed status track and leave a note at every step, so the student always knows what is happening.

Built with Flutter, Riverpod, Firebase Authentication, Cloud Firestore and Firebase Storage. Runs on the iOS simulator (tested on iPhone 17 Pro, iOS 26.5).

Demo video: https://youtu.be/KK-rRvw1BTc

![Snagboard screens](report/figures/screens.png)

## Try it

- Students: sign up in the app with your own ALU email (`name@alustudent.com`). Firebase sends a verification link to that inbox; tap it, return to the app and tap I've verified.
- Staff: sign up the same way with an `@alueducation.com` address and you are staff automatically after verifying.

## Features

- Sign up, sign in, sign out and password reset. Only `@alustudent.com` and `@alueducation.com` addresses can join, and the email must be verified before the app opens.
- File a snag in four steps (What, Where, Details, Review): category, urgency, location, title, description, optional photo, and an option to hide your name from other students.
- Before filing, open snags with the same category and place are shown, with "Affects me too" instead of a duplicate report.
- Campus board with search, category filters and a status ribbon (open, in progress, closed).
- Details screen with the photo and a ticket log of every status change, who made it and their note.
- Staff queue sorted for triage (urgent first, then most affected, then oldest). Staff move a snag through Submitted, Acknowledged, In progress, Resolved or Declined, and must write a note each time.
- Owners can edit or withdraw a snag while it is still submitted. Staff can remove spam.
- Profile with photo, degree or department, an incident report summary and recent snags.

## Roles and access control

A verified `@alueducation.com` account becomes staff automatically at sign-up; every `@alustudent.com` account is a student. The project owner can also change anyone's role in the Firebase Console (Firestore, `users`, set `role`). The app itself can never grant staff to a student. Firestore and Storage security rules enforce every permission on the server: only staff can change a status, students can only edit their own submitted snags, nobody can rewrite the history, and unverified or non-ALU accounts cannot read anything.

## Project structure

```
lib/
  main.dart     app start
  data/         models, and the only code that talks to Firebase (Auth, Firestore, Storage)
  state/        Riverpod providers and controllers the screens share
  ui/           theme, shared widgets and the screens
firestore.rules, storage.rules   server-side access control
test/          app logic tests
rules_test/    security rules tests on the Firestore emulator
```

## Run it

Requirements: Flutter 3.47, Xcode with an iOS simulator, Node 20+, the Firebase CLI, and Java for the emulators.

```
flutter pub get
flutter run -d "iPhone 17 Pro"
```

The app connects to the Firebase project configured in `lib/firebase_options.dart`. To use your own project, run `flutterfire configure`, enable Email/Password sign-in and Storage, then deploy the rules with `firebase deploy --only firestore:rules,storage`.

## Tests

```
flutter test                              # app logic
cd rules_test && npm install && npm test  # security rules, needs the Firebase CLI and Java
```

## Report

The technical report is in `report/`.
