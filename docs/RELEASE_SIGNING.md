# Android Release Signing

CareTrack does not use debug signing for release builds.

To prepare a release keystore locally:
1. Create your Android upload keystore.
2. Add a local `android/key.properties` file with:
   - `storeFile=...`
   - `storePassword=...`
   - `keyAlias=...`
   - `keyPassword=...`
3. Keep the keystore file and `key.properties` local only.
4. Do not commit them to the repository.

The Android Gradle configuration will use release signing only when the local
`key.properties` file exists.
