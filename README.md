
# MindLedger (Flutter + Supabase)

Behavior-first expense tracking with manual entry, message parsing, and insights.

## Phase Order (Implemented)

1. Auth + data storage (Supabase)
2. Transaction parsing (rule-based)
3. Insight engine (behavior analysis)
4. Mobile UI (dashboard, add, list, insights, settings)
5. Automation placeholder (Android)
6. Security (RLS policies)
7. Deployment guidance (Supabase hosting)

## Supabase Setup

1. Create a Supabase project.
2. Open the SQL editor and run `supabase/schema.sql`.
3. Copy the Project URL and anon key from Settings ? API.

## Run The App

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If you run without the `--dart-define` values, the app shows a setup screen.

## Authentication

- Email + password auth is enabled by default in Supabase.
- Sign up, then sign in from the app.

## Automation (Android)

Automation is enabled in Settings. It listens for incoming SMS and notifications while the app is running.

Steps:

1. Grant SMS permission when prompted.
2. Enable Notification access in system settings when prompted.

Notes:

- Notification listening uses the Android notification access service.
- SMS/Notification capture may be restricted by Google Play policy; verify compliance before release.

These require Android permissions and Play Store compliance checks.

## Deployment

- Supabase hosts your database and auth.
- Build release APK/IPA as usual.

## Project Structure (Flutter)

- `lib/screens` UI screens
- `lib/services` parser + insight engine
- `lib/state` app state
- `lib/theme` styling
- `supabase/schema.sql` backend schema + policies
