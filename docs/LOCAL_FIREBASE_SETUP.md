# Local Firebase Setup

CareTrack keeps Firebase platform configuration local-only.

Required local files:
- `android/app/google-services.json`
- `lib/firebase_options.dart` if you choose to generate it locally

Setup steps:
1. Sign in to Firebase CLI with your own account.
2. Run FlutterFire configuration locally for the CareTrack Firebase project.
3. Keep generated Firebase files on your machine only.
4. Do not commit Firebase platform config files to the public repository.

The app bootstrap will show a clear runtime error if Firebase is enabled but the
required local platform files are missing.
