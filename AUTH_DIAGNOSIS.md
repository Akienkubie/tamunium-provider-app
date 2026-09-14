# TAMUNIUM Provider App Authentication Diagnosis

## Findings

The repository currently contains a Flutter starter archive at `tamunium_provider_app_flutter.zip`. The app uses Supabase email/password authentication through `supabase.auth.signInWithPassword`; it does not authenticate against passwords stored in `public.profiles`, `public.providers`, or `public.customers`.

The active Supabase project is `Tamunium central` (`uzjbduranfsenrmitivp`) and is healthy. It contains Auth users and provider records. Provider records are linked by `providers.user_id` to `auth.users.id`. The provider email fields are currently null, so the email used at login must be taken from Supabase Authentication > Users, not from the provider name or provider table.

The seeded provider Auth emails currently present are:

- `akienkubie+chidi@gmail.com`
- `akienkubie+ibinabo@gmail.com`
- `sweetykwaku+emeka@gmail.com`
- `sweetykwaku+boma@gmail.com`
- `tamuniumcentralnfo+grace@gmail.com`

The previous README example `chidi@example.com` was incorrect and could directly cause the reported invalid-credentials message.

## Required build configuration

Build or run the Flutter app with the same Supabase project URL and the project's anon key:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://uzjbduranfsenrmitivp.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<project-anon-key>
```

The anon key is safe to embed in a client build; never embed the Supabase service-role key in the app.

## Changes in this revision

- Corrected the setup documentation to explain the Auth-versus-profile distinction and list the actual seeded provider emails.
- Preserved actionable Supabase Auth error codes/messages instead of replacing every failure with a generic password error.
- Added a `Forgot password?` flow using `resetPasswordForEmail`.
- Kept database records unchanged; no passwords were inserted into application tables.

## Troubleshooting order

1. Confirm the APK was built with the project URL above and a current anon key.
2. Confirm the exact email exists in Supabase Authentication > Users.
3. Confirm the Auth email is confirmed.
4. Use the password set for that Auth user; adding or editing a `public.providers` row cannot create or change an Auth password.
5. After a successful Auth login, confirm the Auth user ID matches `providers.user_id`. If it does not, the app will sign in but show that the account is not linked to a provider profile.

## Collaboration handoff

When bringing changes from ChatGPT or Claude, provide the generated files, commit/branch, or a patch/diff. The safest workflow is to preserve each change in Git, review it against this authentication contract, and then test it against the same Supabase project before merging.
