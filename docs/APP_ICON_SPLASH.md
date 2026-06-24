# KidCost App Icon And Splash

Issue: #27 `[GRAPHIC] Przygotowac ikone aplikacji i splash screen`

The mobile app now has production-ready MVP launch assets based on the Calm Ledger brand direction.

## Source Files

- `docs/brand/kidcost-app-icon.svg` - full-bleed square source for app icons.
- `docs/brand/kidcost-splash.svg` - centered launch image source with quiet paper background.

## Generated App Assets

Android:

- Legacy launcher PNGs: `apps/mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Adaptive icon XML: `apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`.
- Round adaptive icon XML: `apps/mobile/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`.
- Adaptive foreground vector: `apps/mobile/android/app/src/main/res/drawable/ic_launcher_foreground.xml`.
- Splash mark vector: `apps/mobile/android/app/src/main/res/drawable/launch_mark.xml`.
- Launcher background color: `apps/mobile/android/app/src/main/res/values/colors.xml`.

iOS:

- App icon PNGs: `apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- Launch images: `apps/mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/`.

## Regeneration Notes

These assets were rendered locally from SVG sources with macOS Quick Look and resized with `sips`; no paid external asset dependency is required. If the source SVG changes, regenerate all platform PNGs from `kidcost-app-icon.svg` and `kidcost-splash.svg`, then verify dimensions with `file`.

## Visual Checks

- The app icon has a full opaque background for App Store and Google Play compatibility.
- The mark is simple enough for 20-24 px display and avoids tiny text.
- The splash screen uses the brand mark and calm `Quiet Paper` background rather than the default Flutter placeholder.
