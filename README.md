# Pharmacy Unit

Flutter app connecting doctors / pharmacists with medical-supply suppliers.
Provider state management, MVVM folder layout, SQLite storage, Firebase Auth (real OTP) and FCM push.

## Structure

```
lib/
  core/          constants, theme, routes, validators, formatters
  data/
    local/       SQLite helper (schema + migrations)
    models/      plain data classes
    repositories/  SQL access per domain
    services/    Firebase auth, FCM, PDF invoice
  viewmodels/    ChangeNotifiers (all screen state / logic)
  views/         screens: splash, onboarding, auth, user, supplier, admin, common
  widgets/       reusable components
```

## Roles

| Role | Tabs |
|---|---|
| Doctor / Pharmacist | Home · Order · Explore (rates, request item, invoice) · Profile |
| Supplier | Home · Suppliers · Orders · Profile |
| Admin | Requests (approve/reject) · Catalog · Account |

Admin = any account whose email is listed in `AppConstants.adminEmails`
(default `admin@pharmacyunit.com`). Create it once in Firebase Console → Authentication.

## Firebase setup (required to log in)

1. Create a Firebase project, add an Android app with package `com.example.pharmacy_unit`
   (change it in `android/app/build.gradle.kts` if you prefer).
2. Download `google-services.json` into `android/app/`. The Google Services Gradle plugin is
   applied automatically once that file exists.
3. Authentication → Sign-in method: enable **Email/Password**.
4. Cloud Messaging works with the same file. Send a test message from Firebase Console
   (foreground messages are saved to the in-app notification list). Devices subscribe to
   the topic `role_user` / `role_supplier`.

## Auth flows

- **Sign up** (doctor / pharmacist / supplier): creates a Firebase Auth email + password account, then saves the profile locally.
- **Log in**: email + password.
- **Reset password**: Firebase sends a reset link to the email.

## Known limitations

- SQLite is per device. Orders, users and requests are not shared between phones;
  cross-device order flow needs a cloud backend (e.g. Firestore) behind the repositories.
- Push messages must be sent from the Firebase console or a server; the app cannot
  push to another user's device by itself. Status changes are recorded in the in-app
  notification list.
