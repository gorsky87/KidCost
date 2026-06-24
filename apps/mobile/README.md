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
