# Fix Google Sign-In (Error 10 / Not Working)

Follow these steps **in order** if "Continue with Google" fails or shows Error 10.

## 1. Get the correct SHA-1 and SHA-256

In a terminal, from your **project root** (finshe folder):

**Windows (PowerShell or CMD):**
```bash
cd android
gradlew signingReport
```

Look for **Variant: debug** and copy:
- **SHA-1:** (e.g. `A1:B2:C3:D4:...`)
- **SHA-256:** (e.g. `E5:F6:...`)

Alternative (debug keystore only):
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android
```

## 2. Add them in Firebase

1. Open [Firebase Console](https://console.firebase.google.com) → your project **finshe-99ae8**.
2. Click the **gear** (Project settings) → **General**.
3. Under **Your apps**, select your **Android** app (`com.example.finshe`).
4. Click **Add fingerprint**.
5. Paste **SHA-1** → Save.
6. Click **Add fingerprint** again and paste **SHA-256** → Save.

## 3. Download the new config

1. On the same **Your apps → Android** page, click **Download google-services.json** (or the download icon).
2. **Replace** the file in your project:
   - Put the downloaded file at: **android/app/google-services.json**
   - Overwrite the existing file completely.

## 4. Enable Google Sign-In

1. In Firebase Console go to **Authentication** → **Sign-in method**.
2. Click **Google** → turn **Enable** ON → **Save**.

## 5. Clean and reinstall the app

In the project root:

```bash
flutter clean
flutter pub get
flutter run
```

**Important:** Uninstall the Finshe app from your phone/emulator first, then run `flutter run` again so the new config is used.

## 6. If it still fails

- Confirm **package name** in Firebase Android app is exactly: `com.example.finshe`.
- In [Google Cloud Console](https://console.cloud.google.com) → **APIs & Credentials** → **Credentials** → under **OAuth 2.0 Client IDs** find the **Android** client for this app and check that the **SHA-1** is listed there (Firebase usually syncs this).
- Make sure you are testing with the **same** keystore: `flutter run` uses the **debug** keystore, so the SHA-1 you added must be from the **debug** keystore (from step 1).
