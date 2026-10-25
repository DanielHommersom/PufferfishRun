# PufferAds — native iOS plugin (US-22, US-23, US-25)

Registers two Godot singletons:

| Singleton | Used by | Purpose |
|---|---|---|
| `PufferAds` | `scripts/ad_manager.gd` | UMP consent (EEA/UK) → ATT prompt → `GADMobileAds.start` → interstitial load/show |
| `LegacyDefaults` | `scripts/save_manager.gd` | `read_legacy_defaults()` → `{highScore, selectedSkin, isMuted}` from the Swift build's `NSUserDefaults` |

Without the built plugin the game runs fine: AdManager is a no-op and migration is skipped.

## Status
Source only — **not compiled or device-tested yet**. Build it, then run the checklist below.

## Build
1. Download the iOS SDKs (versions match the Swift build's `Package.resolved`) and place the
   `.xcframework`s next to `PufferAds.gdip`:
   - `GoogleMobileAds.xcframework` (13.3.0)
   - `UserMessagingPlatform.xcframework` (3.1.0)
2. Generate Godot headers for 4.7 (in a Godot 4.7 source checkout):
   `scons platform=ios target=template_release` (only the generated headers are needed).
3. Compile `src/*.mm` into a static library for `ios-arm64` and `ios-arm64-simulator` with the
   Godot source dir on the include path and `-DIOS_ENABLED -DAPPLE_EMBEDDED_ENABLED`, then
   `xcodebuild -create-xcframework … -output PufferAds.xcframework`.
   (The `godot-ios-plugins` repo's SConstruct is a good template.)
4. In the iOS export preset enable **Plugins → PufferAds**.

## Device checklist
- First launch: consent form (EEA, debug geography forced in debug builds) → ATT prompt ≈3 s after
  launch (after the studio splash) → test interstitial after the 3rd game over.
- ATT denied / airplane mode: game fully playable, no crash, no ads.
- Migration: install the Swift build via Xcode, reach score ≥ 20, choose a skin, install the Godot
  build over it (same bundle id) → best score and skin are kept; second launch does not migrate again.
