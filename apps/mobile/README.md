# KidCost Mobile

Flutter shell for the KidCost MVP.

## Local development

```sh
flutter pub get
flutter test
flutter run
```

Supabase client credentials are not committed. Pass them at runtime when the
SDK is connected:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-key
```
