Direct-download APK hosting (Firebase)
=====================================

1. Build and copy APK into this folder:
   powershell -ExecutionPolicy Bypass -File ..\build_release_apk.ps1

2. From the finshe project root, deploy:
   firebase deploy --only hosting

3. Share these URLs:
   - Landing page:  https://YOUR_PROJECT.web.app/
   - Direct APK (auto-download when opened):  https://YOUR_PROJECT.web.app/FinShe-release.apk

The firebase.json "headers" rule forces browsers to download the .apk instead of displaying it.

Optional: only share the direct .apk URL — clicking it starts the download on most devices.
