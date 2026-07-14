# Firebase Cloud Messaging (Push) Setup

The app integrates Firebase Cloud Messaging (FCM) for new-job push
notifications (`lib/core/services/push_notification_service.dart`). The Dart
code is complete and guarded: if the Firebase config files below are missing,
`PushNotificationService.initialize()` logs a warning and no-ops instead of
crashing. Push only starts working once the platform config is added.

## What is missing (binary/config, cannot be generated in-repo)

You must create a Firebase project (or use the existing `relaydrivers` project)
and download the platform config files:

| Platform | File | Destination path |
|----------|------|------------------|
| Android  | `google-services.json` | `android/app/google-services.json` |
| iOS      | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` (add to the Runner target in Xcode) |

Both are gitignored-sensitive; store them via CI secrets for release builds.

## Android wiring

1. Add the Google Services Gradle plugin.
   - In `android/settings.gradle.kts` plugins block:
     `id("com.google.gms.google-services") version "4.4.2" apply false`
   - In `android/app/build.gradle.kts` plugins block:
     `id("com.google.gms.google-services")`
2. Drop `google-services.json` into `android/app/`.
3. `POST_NOTIFICATIONS` (Android 13+) is already declared in
   `AndroidManifest.xml`; the runtime prompt is requested by
   `FirebaseMessaging.requestPermission()`.

## iOS wiring

1. Add `GoogleService-Info.plist` to the Runner target in Xcode.
2. In Xcode, enable the **Push Notifications** capability and the
   **Background Modes > Remote notifications** capability on the Runner target.
3. Upload the APNs auth key (`.p8`) to the Firebase project (Project Settings >
   Cloud Messaging > Apple app configuration).
4. `NSLocationWhenInUse...` and related usage strings are already in
   `Info.plist`.

## Backend gap (TODO)

Device-token registration has no backend route yet. The client already obtains
the FCM token and attempts to register it; the call is a no-op until the route
ships. Expected contract (see `ApiConfig.deviceRegister`):

```
POST /driver/devices
  { "platform": "android" | "ios" | "web", "token": "<fcm-token>" }
  -> 200 { "success": true }
```

The backend should send a data message with `data.type = "new_job"` (or
`job_updated` / `job_cancelled`) when a job is offered/changes; the app refreshes
the jobs list on receipt.
