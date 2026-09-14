# TAMUNIUM Provider App — Flutter Starter

Covers: Auth (email/password) -> Home (availability toggle + summary) ->
Available Jobs (accept/reject, realtime) -> My Jobs (Active/History tabs) ->
Job Detail (start/complete flow).

## Setup

1. Unzip into a fresh Flutter project, or copy `lib/` and `pubspec.yaml`
   into an existing one (`flutter create tamunium_provider_app` first if
   starting fresh, then overwrite `lib/` and `pubspec.yaml`).
2. `flutter pub get`
3. Run with your real Supabase keys:

```
flutter run --dart-define=SUPABASE_URL=https://uzjbduranfsenrmitivp.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

4. Log in with the exact email address created in Supabase
   Authentication -> Users and the password set for that Auth user. The
   provider name or a row inserted into `public.providers` is not a login
   credential. In the current Tamunium project, the seeded provider emails
   are `akienkubie+chidi@gmail.com`, `akienkubie+ibinabo@gmail.com`,
   `sweetykwaku+emeka@gmail.com`, `sweetykwaku+boma@gmail.com`, and
   `tamuniumcentralnfo+grace@gmail.com`.

If sign-in fails, first confirm that the APK was built with the URL above and
the project's anon key using `--dart-define`. Then verify the exact email and
email-confirmed status under Authentication -> Users. Do not add passwords to
`public.profiles`, `public.providers`, or `public.customers`; those tables are
application profiles and are not used by Supabase Auth for password checking.

## Onboarding and password reset

The login screen includes `Create a new account`, where a person can choose
Provider or Customer, enter a name and email, set a password, and confirm the
password. Supabase Auth owns the password; after authentication the app creates
the matching row in `public.profiles` and either `public.providers` or
`public.customers` using the signed-in user's ID. Email confirmation remains
controlled by Supabase Auth settings.

Password fields include an eye button to show or hide what was typed. The
forgot-password email uses the mobile redirect
`com.tamunium.provider://reset-password`. Add that exact URL under Supabase
Authentication -> URL Configuration -> Redirect URLs before testing password
reset links on a phone. Do not use `http://localhost:3000` as a mobile redirect.

## How it maps to the backend

- **Auth**: `AuthService` wraps `supabase.auth.signInWithPassword`. Swap
  for `signInWithOtp(phone: ...)` later for phone-first onboarding —
  nothing downstream needs to change since everything else keys off
  `auth.uid()`.
- **currentProviderProvider**: looks up the `providers` row where
  `user_id = auth.uid()`. RLS's `providers_select` already allows any
  authenticated user to read this, so no extra policy work needed.
- **myJobsStreamProvider**: one realtime subscription on `jobs` filtered
  to `assigned_provider_id = <this provider>`. Screens (`Available`,
  `Active`, `History`) all derive from this single stream by filtering on
  `status` client-side, so there's only one open realtime channel instead
  of three.
- **Accept/Reject/Start/Complete**: all go through `JobsRepository`,
  which writes only the fields RLS's `jobs_update` policy allows a
  provider to touch (status, timestamps, notes) — it deliberately never
  writes `rate_amount` or `assigned_provider_id`, matching the `WITH
  CHECK` clause on that policy.

## Known gaps to fill in next

- No push notifications yet for new job offers (currently relies on the
  realtime stream while the app is open).
- No photo upload on job completion (schema has `photos` conceptually via
  a future `job_photos` table or a `photos` JSONB column — not yet in the
  schema you ran).
- No earnings screen yet — `provider_earnings` table is ready on the
  backend, just needs a repository + screen following the same pattern
  as `JobsRepository`.
