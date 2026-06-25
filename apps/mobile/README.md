# KidCost Mobile

Flutter shell for the KidCost MVP.

## Local development

```sh
flutter pub get
flutter test
flutter run -d <android-device-id>
```

Supabase client credentials are not committed. Pass them at runtime when the
SDK is connected:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-key
```

## Local Android demo

Use an Android emulator or physical Android device for the local demo. The
current local iOS path is intentionally excluded until full Xcode is installed
and selected with `xcode-select`.

For a working local app backed by Supabase, start the local backend first:

```sh
cd ../..
supabase start
supabase db reset
supabase status
```

Copy the `anon key` from `supabase status`, then run the mobile app against the
local backend. Android emulators reach host-machine services through
`10.0.2.2`, so use that host instead of `127.0.0.1`:

```sh
cd apps/mobile
flutter emulators --launch kidcost_demo_api36
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key-from-supabase-status>
```

After the first Supabase image download, the fast path is:

```sh
supabase start
cd apps/mobile
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon-key-from-supabase-status>
```

```sh
sdkmanager "system-images;android-36;google_apis;arm64-v8a"
avdmanager create avd \
  --name kidcost_demo_api36 \
  --package "system-images;android-36;google_apis;arm64-v8a" \
  --device pixel_7
flutter emulators --launch kidcost_demo_api36
flutter devices
flutter run -d emulator-5554
```
