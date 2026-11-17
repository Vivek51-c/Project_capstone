# Opportune: JobMate — Flutter Frontend

Talks to the FastAPI backend (see `../backend`). Implements all 6 features:
JobRadar, JobMatcher, CareerMatch, SkillBridge, ResumeBuilder, ATS TuneUp.

## ⚠️ Important: not yet compiled/tested (still true as of Stage 2)

This code was written in a sandbox with **no Flutter SDK available** (no
network access to `pub.dev` / `storage.googleapis.com` to install one), so
unlike the backend, none of this has been run through `flutter analyze`,
`flutter pub get`, or an actual build — this was already true for the
original 6 tools and remains true for the Stage 2 auth/profile additions
below. I checked it by hand for import correctness, bracket balance, and
class/method cross-references (see "Manual verification performed" at the
bottom), but **please run `flutter analyze` and `flutter test` first
thing** and expect to fix a handful of small issues — normal for
hand-written Flutter that hasn't touched a compiler yet.

## Run it

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Backend must be running first (see `../backend/README.md`).

**Android emulator**: the backend on your host machine is reachable at
`10.0.2.2`, not `127.0.0.1`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Physical device**: use your machine's LAN IP instead, and make sure the
device is on the same network and your firewall allows the connection.

## Structure

```
lib/
  main.dart                    # app entry, routes, shared ApiClient + SessionController
  core/
    api_config.dart            # base URL, ApiException
    api_client.dart            # every backend call, incl. multipart uploads + auth/profile
    app_theme.dart
    auth/
      auth_models.dart         # AuthUser, AuthResult (mirrors backend UserOut/TokenResponse)
      token_storage.dart       # flutter_secure_storage wrapper -- JWT only, never a password
      session_controller.dart  # SessionController (ChangeNotifier) + SessionScope (InheritedNotifier)
      validators.dart          # client-side mirrors of backend validation rules
    profile/
      profile_models.dart      # ProfileData, ProfileUpdate, EducationItem, ExperienceItem
  models/                      # one file per tool, mirrors the backend's Pydantic schemas
  widgets/
    common_widgets.dart        # legacy: FeatureTile, ScoreGauge, SkillChipList, etc.
    ui_kit.dart                 # current design-system barrel export (colors/spacing/buttons/etc.)
    file_upload_card.dart      # resume/JD picker (file_picker package)
    auth/
      app_text_field.dart      # shared text field w/ password visibility toggle
  screens/
    home_screen.dart           # unchanged except a profile avatar button in the AppBar
    job_radar_screen.dart
    job_matcher_screen.dart
    career_match_screen.dart
    skill_bridge_screen.dart
    ats_screen.dart
    resume_builder_screen.dart # 9-step Stepper wizard
    auth/
      auth_gate.dart           # app root: splash -> restores session -> Home or Login
      login_screen.dart
      signup_screen.dart
      forgot_password_screen.dart
      reset_password_screen.dart
    profile/
      profile_screen.dart
      edit_profile_screen.dart
```

## Design choices worth knowing about

- **No state-management package** (no Provider/Riverpod/Bloc) — each screen
  owns its own `StatefulWidget` state and calls the shared `apiClient`
  singleton directly. Simple and sufficient for this app's size; revisit if
  screens start needing to share live state with each other.
- **File uploads use raw bytes** (`file_picker` with `withData: true`)
  rather than file paths, so the same code works on mobile, desktop, and
  web without platform-specific branches.
- **ResumeBuilder's AI-enhance path will feel slow** (10-20+ seconds) —
  this mirrors the backend's current blocking `time.sleep(3)`-per-section
  Gemini throttle, called out as a follow-up in the backend README. The
  `LoadingButton` widget at least shows a spinner the whole time so it
  doesn't look frozen.
- **ResumeBuilder validation is a separate "Check for issues" button**
  rather than live-as-you-type, to avoid hitting the API on every
  keystroke. Wire it to `onChanged` debounced calls later if you want live
  validation.

## Authentication & session (Stage 2)

- **`SessionController`** (`core/auth/session_controller.dart`) is the single
  source of truth for "who's signed in". It's created once in `main.dart`
  and provided to the whole widget tree via **`SessionScope`**
  (`SessionScope.of(context)`), an `InheritedNotifier` -- any widget that
  reads it rebuilds automatically on login/logout/user changes. No
  Provider/Riverpod/Bloc package was added; this is plain Flutter, keeping
  the "no state-management package" choice from Stage 1 intact.
- **App launch**: `AuthGate` (`screens/auth/auth_gate.dart`) is now the
  actual `'/'` route. It shows a small splash while `SessionController.restore()`
  reads any stored token and validates it with a real `GET /auth/me` call,
  then swaps to `HomeScreen` or `LoginScreen` -- there is no way to reach
  `HomeScreen` without either a freshly-restored, backend-validated
  session or an explicit login/signup.
- **Token storage**: `core/auth/token_storage.dart` wraps
  `flutter_secure_storage` and stores **only** the JWT access token --
  never the password, never anything else. On Android this uses
  EncryptedSharedPreferences (Keystore-backed); on Flutter Web there is no
  OS-level secure storage, so the plugin falls back to browser storage
  protected with a WebCrypto-derived key. That's fine against casual
  inspection but **not** against an XSS attack that can run JS in the
  page -- there is no way to make a token fully un-stealable from a pure
  browser app. Treat any XSS bug in this app as equivalent to a token leak
  on the web build.
- **Authorization header**: every authenticated `ApiClient` call
  (`getMe`, `getProfile`, `updateProfile`, `changePassword`, `logout`)
  takes the token explicitly and sends `Authorization: Bearer <token>`.
  Public calls (JobRadar, JobMatcher, etc.) are completely untouched and
  still require no token.
- **401 handling**: `ProfileScreen` and `EditProfileScreen` both check for
  a 401 from the backend and call `session.forceSignOut()` rather than
  showing a generic error -- this is what happens if, e.g., the user
  changed their password on another device and the backend revoked this
  device's token (see backend `AUTH_SETUP.md`, `token_version`). `AuthGate`
  then automatically swaps back to `LoginScreen`.
- **Logout**: `ProfileScreen`'s Logout button asks for confirmation, then
  calls `SessionController.logout()`, which best-effort calls
  `POST /auth/logout` (server-side this only confirms the token was
  valid -- see backend docs, JWTs are stateless) and then unconditionally
  clears the local token regardless of whether that call succeeded.

## Deep link configuration (required for real "reset password" emails)

Today, tapping **Send reset link** calls the real backend, and in
development (no SMTP configured) the *generic* success message is shown
plus a clearly-labeled dev-only banner with a button that jumps straight to
`ResetPasswordScreen` in-app -- this never appears in a production build
(gated on `kReleaseMode` in addition to the backend's own production gating).

In production, the emailed link must open this app directly at
`ResetPasswordScreen` with the token. `main.dart` already handles the Flutter
side of this (`onGenerateRoute` parses `/reset-password?token=...`); what's
missing is the platform-level deep link registration, which lives in
`android/` and `web/` -- **not included in this ZIP** (only `lib/` and
`pubspec.yaml` were provided), so add these to your actual project:

**Android** (`android/app/src/main/AndroidManifest.xml`, inside the main
`<activity>` for `FlutterActivity`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Use your real domain for App Links (autoVerify requires
         a hosted /.well-known/assetlinks.json on that domain) -->
    <data android:scheme="https" android:host="app.opportunejobmate.com" android:pathPrefix="/reset-password" />
</intent-filter>
```
Flutter's default Android embedding turns a matching link into the initial
route automatically; no extra Dart code is needed beyond what's already in
`main.dart`. If you'd rather use a custom scheme instead of a verified App
Link (simpler, but shows a disambiguation dialog instead of opening
directly), add a second `<data android:scheme="opportunejobmate" />` filter
and set `FRONTEND_BASE_URL` on the backend accordingly (see backend
`.env.example`).

**Flutter Web**: no extra config needed beyond what's already here --
`/reset-password?token=...` is a normal URL path once you serve with
`flutter run -d chrome --web-hostname=... ` or a real web deployment using
path-based routing (`flutter build web` default). If the deployed site uses
hash-based routing instead, the link becomes
`https://your-domain/#/reset-password?token=...`; either way
`onGenerateRoute`'s `Uri.parse(settings.name)` handles the query string
correctly since Flutter strips the routing prefix before it reaches
`settings.name`.

Either way, set the backend's `FRONTEND_BASE_URL` env var to the real
origin the emailed link should point at (see backend `.env.example`) --
this is what the backend uses to build the link.

## Backend base URL configuration

Precedence for backend base URL resolution in [lib/core/api_config.dart](lib/core/api_config.dart):
1. Explicit `--dart-define=API_BASE_URL=...` compile-time flag
2. `.env` file (`API_BASE_URL=https://...`)
3. Production Render backend fallback (`https://opportune-jobmate-api.onrender.com`)

The timeout is configured to **60 seconds** by default to allow for cold-start wakeups on Render free-tier instances.

## Deploying to Vercel (Production)

This repository includes full Vercel deployment support out of the box via `vercel.json` and `vercel-build.sh`.

### Option 1: Git Integration via Vercel Dashboard (Recommended)

1. Push this frontend repository to **GitHub** (or GitLab/Bitbucket).
2. Go to [vercel.com](https://vercel.com) and click **"Add New Project"**.
3. Import your repository.
4. In the Project Configuration:
   - **Framework Preset**: Select **"Other"** (or leave as detected).
   - **Root Directory**: `./` (all project files are now at the root).
   - **Build Command**: `bash vercel-build.sh` (or `npm run build` — preconfigured).
   - **Output Directory**: `build/web` (preconfigured in `vercel.json`).
5. **Environment Variables**:
   - Add `API_BASE_URL`: Enter your deployed Render backend URL (e.g. `https://your-backend.onrender.com`).
   - Add `APP_ENV`: `production`
   - Add `API_TIMEOUT_SECONDS`: `60`
6. Click **Deploy**. Vercel will install the Flutter stable SDK and compile the web bundle automatically!

### Option 2: Deploying via Vercel CLI

If you have Flutter installed locally:
```bash
# 1. Build the production web bundle locally with your Render backend URL
flutter build web --release --dart-define=API_BASE_URL=https://your-backend.onrender.com

# 2. Deploy the static build directly using Vercel CLI
npx vercel --prod
```

### Option 3: Automated GitHub Actions

A ready-to-use GitHub Actions workflow is provided in `.github/workflows/deploy-vercel.yml`. Simply add `API_BASE_URL`, `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID` in your repository's GitHub Secrets.

### ⚠️ Critical Step: Configure CORS on Render Backend!

Because your Flutter Web app runs in client browsers on `https://<your-app>.vercel.app`:
1. Open your **Render Dashboard** for your backend service.
2. Go to **Environment Variables**.
3. Ensure `CORS_ALLOWED_ORIGINS` includes your Vercel frontend URL, e.g.:
   `https://<your-project>.vercel.app,http://localhost:3000` (or `*` for public access).
4. Save and redeploy the backend if needed so browsers do not block API requests.

## Known gaps / next steps

- No loading skeletons on the 6 original tool screens -- unchanged from
  before Stage 2, still worth polishing.
- No offline handling / retry UI beyond a red SnackBar via
  `showErrorSnackBar` on the original tool screens (Profile/auth screens
  use inline banners + `ErrorStateView`'s retry button instead).
- No app icons/splash screen configured yet -- still using Flutter defaults.
- No automated widget/unit tests written for the Stage 2 auth/profile UI
  (the backend has 64 passing pytest tests -- see `../backend/README.md`
  and `AUTH_SETUP.md`). Suggested first tests to add: `AuthValidators`
  (pure functions, trivial to unit test), and a widget test for
  `LoginScreen` mocking `ApiClient`.
- Single-device-token revocation isn't possible yet (only "all of this
  user's tokens" via `token_version` on password change/reset) -- see
  backend `AUTH_SETUP.md`.
- `EditProfileScreen`'s education/experience editors are intentionally
  simple free-text year/date fields (no date picker) to keep this pass
  scoped -- swap in `showDatePicker`/`YearPicker` later if you want
  stricter input.

## Manual verification performed (Stage 2, no Flutter SDK available)

- Every new/changed symbol (widget classes, fields, methods) was
  cross-checked against its actual definition in this codebase via `grep`
  (not assumed from memory) -- e.g. `PrimaryButton.onPressed`'s exact
  signature, `InfoBanner`'s constructor params, `AppColors`/`AppSpacing`/
  `AppRadius` token names, `SkillChip`'s constructor.
- Confirmed there are two `SkillChip` classes in this codebase
  (`widgets/common_widgets.dart`, a legacy file, and `widgets/skill_widgets.dart`,
  exported by `ui_kit.dart`) -- pre-existing, not introduced by Stage 2.
  Every new file imports only `ui_kit.dart`, never `common_widgets.dart`,
  so there's no ambiguous-import risk from the files added here.
- Confirmed every backend field name/type used in `auth_models.dart`,
  `profile_models.dart`, and the new `ApiClient` methods against the actual
  Stage 1/2 backend source (`app/schemas/auth.py`, `app/schemas/profile.py`),
  not from the task description.
- Traced every new route (`/login`, `/signup`, `/forgot-password`,
  `/reset-password`, `/profile`) end-to-end from `main.dart` to its screen.
- I could not verify: package version resolution (`flutter pub get`),
  static analysis (`flutter analyze`), or an actual build/run, since this
  sandbox has no network access to `pub.dev` or the Flutter SDK's own
  download host. Please run these locally as the first step.
