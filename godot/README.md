# Pufferfish Run — Godot 4.7

Rebuild of `swift_original/` according to `userstories/`. Main scene: `scenes/studio_splash.tscn`.

```bash
# logic + scene-flow tests (31 checks)
godot --headless --path godot -s res://tests/run_tests.gd
# render every screen to PNG
godot --path godot --resolution 393x852 -s res://tests/screenshots.gd -- /tmp/shots
```

Debug builds, in the game scene: **H** toggles hitboxes, **1/2/3** force jellyfish/shark/urchin, **0** back to random.

## Story status

| Story | Status | Notes |
|---|---|---|
| US-01 setup | ✅ | 393×852, portrait, 60 ticks, `scripts/constants.gd`. Font: `SystemFont` → Courier New Bold (ships with iOS/macOS, the original font); see `assets/fonts/README.md` |
| US-02 SaveManager | ✅ | `user://save.cfg`, Swift key names, write-on-change, `submit_score` |
| US-03 SceneRouter | ✅ | FADE / MOVE_IN_UP / MOVE_IN_DOWN, params, input blocked + double taps ignored |
| US-04 fish control | ✅ | Per-tick physics; multi-touch counts active touches; mute-button taps ignored |
| US-05 fish visuals | ✅ | `_draw()`, `DrawUtil.draw_menu_fish` / `draw_card_fish` |
| US-06 coral | ✅ | Drawn once per pillar, deterministic patterns |
| US-07 score/difficulty | ✅ | `scripts/difficulty.gd`, tested at score 0/20/40 |
| US-08 collisions | ✅ | Same math, no physics bodies, debug hitboxes |
| US-09–12 enemies | ✅ | One `Enemy` script. **B12 fixed**: shark teeth at the mouth |
| US-13 ocean | ✅ | Zone tween 2 s, reusable `BubbleField` |
| US-14 death | ✅ | |
| US-15 studio splash | ✅ (PopPulse style) | Vector logo `scripts/dd_logo.gd` (shared with PopPulse) inside `SplashSequence` |
| US-16 splash · US-17 menu · US-18 skins · US-19 game over | ✅ | **B2 fixed** (NEW BEST only when strictly higher). Skins in `data/skins.tres`; grid scrolls if > 6 |
| US-20 SFX · US-21 mute | ✅ | WAVs generated at startup with the exact Swift formulas; audio session Ambient + mix with others; drawn speaker icon |
| US-22 ATT/UMP/AdMob · US-23 interstitials | ✅ (same plugins as PopPulse) | `scripts/ad_manager.gd` on Poing AdMob 5.1 (`addons/admob`, UMP included) + Godotx ATT 3.0 (`ios/plugins/att`). App `~2391980768`, rewarded `/9385094409`, interstitial `/8765817424` |
| US-24 iOS export | ⚠️ preset done | `export_presets.cfg`: same bundle id, 1.1 (build 2), min iOS 15, icon, launch-screen colour, privacy manifest. Team ID/signing empty; `SKAdNetworkItems` only contains Google's own id — paste Google's full list before release |
| US-25 migration | ✅ (to test on device) | `scripts/legacy_defaults.gd` reads the Swift build's NSUserDefaults plist directly (binary plist parser, no native code) |
| US-26 moving pillars | ✅ behind flag | `Constants.MOVING_OBSTACLES_ENABLED = false`, range 60 px |
| US-27 depth label | ✅ behind flag | `Constants.DEPTH_LABEL_ENABLED = false`, placed bottom-left |

## Monetisation (beyond the original)
| Feature | Where | Notes |
|---|---|---|
| Rewarded "CONTINUE?" | `scripts/revive_panel.gd`, `game.gd` | Once per run from score 2, 5 s countdown, clears pillars ahead + 2 s invulnerability |
| Interstitial rules | `AdManager.should_show_interstitial` | Grace 5 lifetime games, ≥ 75 s apart, every 3rd game, never after a new best or a rewarded video; shown on the PLAY AGAIN / MAIN MENU tap |
| Coins + skin shop | `coin.gd`, `skin_select.gd`, `SaveManager` | 60 % of pillars carry a coin; skins unlock by score **or** coins (60–500); "2× COINS" rewarded on game over |
| Settings | `scenes/settings.tscn` | Sound, Remove Ads, restore purchases, UMP privacy options, privacy policy, support, version |
| Remove Ads (IAP) | `scripts/purchase_manager.gd` | Non-consumable `digitaldiamonds.pufferfishrun.removeads` via RevenueCat (Godotx RevenueCat 2.5, `ios/plugins/revenue_cat`), entitlement `no_ads`. StoreKit test file: `ios/PufferfishRun.storekit` |
| Shop | `scripts/skin_select.gd`, `cosmetics.gd` | Tabs SKINS (6 earnable + 6 shop-only) / HATS (7) / TRAILS (4); equip without leaving; rewarded "+25 FREE" max 3× per day |

Tests and screenshot scripts use `user://save_test.cfg`, never the real save.
Without the native plugins, debug builds **simulate** rewarded videos (0.8 s) and the Remove Ads purchase so revive/2× coins can be tested on a Mac; release builds hide them.
**Before release:** create the Remove Ads product in App Store Connect (same id), add the `InAppStore` plugin, create a rewarded ad unit and set `AdManager.PROD_REWARDED`, and verify `Constants.PRIVACY_POLICY_URL`.

## Retention & game feel
| Feature | Where | Notes |
|---|---|---|
| Onboarding | `tutorial_overlay.gd`, `game.gd` | GET READY state (nothing moves until the first tap) with animated hand; first 3 gaps +90/+60/+30 px during a player's first 3 games; optional start shield (30 coins or rewarded) |
| Near miss | `game.gd` `_track_near_miss` | Passing within 7 px of coral: "CLOSE!" +1 coin, haptic |
| Power-ups | `power_up.gd`, `power_up_hud.gd` | From score 3, 14 % of gaps: SHIELD (absorbs one hit), MAGNET (8 s), SLOW-MO (5 s, world at 60 %) |
| Zones | `constants.gd`, `zone_decor.gd`, `shaders/darkness.gdshader` | 6 zones (0/10/20/35/50/70): reef, kelp forest, open water, shipwreck, deep ocean, abyss (darkness with light around the fish). Zone banner + depth in metres |
| Daily reward | `daily.gd`, `daily_reward_panel.gd` | 7-day streak (20…150 coins), 2× with rewarded; pops up once per session |
| Missions | `daily.gd`, `scenes/missions.tscn` | 3 per day from a pool of 7 types, deterministic per day |
| Daily challenge | `daily.gd`, `challenge_panel.gd` | Same coral for everyone (seeded per day), rotating modifier, target 15 → 60 coins once per day; no revive; doesn't count for the normal best |
| Settings | `settings.gd` | Sound, vibration, screen shake, language (auto + 7) |
| Translations | `assets/i18n/strings.csv` | en, nl, de, fr, es, pt_BR, ja (128 keys); button text auto-shrinks for long languages; CJK via system-font fallback |

## Launch order (aligned with PopPulse)
1. iOS launch screen = `assets/launch/launch@2x/@3x.png` (rendered by `tools/launch_images.gd` from the ocean shader) — no Godot logo.
2. Godot boot splash = the same image (`application/boot_splash/image`, stretch Cover).
3. `SplashSequence` over the already-built menu: Digital Diamonds (glow, spring-in, 2 shimmer pulses + shine) → Pufferfish Run (fish pops in, title pulses) → fade to menu. Tap skips the current splash; test runs skip it.
4. Daily reward popup.
5. Ads: nothing at launch; after the first finished game: UMP consent → own explainer (`att_explainer_panel.gd`) → Apple ATT → Mobile Ads.

## Intentional deviations
- Screens are plain `Node2D` trees (no `CanvasLayer`), so the move-in slides the whole screen, mute button included, like SpriteKit did.
- On iPhone SE the `expand` stretch gives a 479×852 viewport (wider, not shorter), so the menu never gets cramped vertically.
- Title shadows are label shadows that fade/move with the text (the original left static shadows behind).
- Urchin spines keep the original horizontal base offset (parity).
- The menu's HOLD/RELEASE panel is replaced by the DAILY / MISSIONS / CHALLENGE row (the GET READY screen teaches the controls).
- The run starts on the first tap instead of immediately (the original fish started falling at once).

## Not verified here
Physical-device runs, 60 fps on the oldest device, TestFlight, side-by-side comparison with the Swift build, and everything that needs the native plugin.
