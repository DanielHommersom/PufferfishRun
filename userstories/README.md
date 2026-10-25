# PufferfishRun — Godot rebuild: user stories

Bron: `swift_original/` (SpriteKit + SwiftUI, iOS 26.2, bundle id `digitaldiamonds.pufferfishrun`, v1.0).
Doel: `godot/` (Godot 4.7, Mobile renderer, stretch `canvas_items` / `expand`).

## Wat de game is
Endless side-scroller, portrait. Je bent een kogelvis die links op het scherm blijft (x = 25% schermbreedte).
**Ingedrukt houden = opblazen = stijgen**, **loslaten = leeglopen = zakken**. Koraalzuilen met een opening komen van rechts;
elke gepasseerde zuil = +1 punt. Vanaf score 5/15/25 komen er vijanden bij (kwal, haai, zee-egel).
Het tempo en de opening worden strakker naarmate de score oploopt. De oceaan wordt donkerder per diepte-zone.
Highscore ontgrendelt 6 skins. Interstitial ad na elke 3e game over.

## Schermflow (origineel)
```
StudioSplash (Digital Diamonds logo, 2.8s, tap = skip)
  → Splash (titel-animatie, 3.2s, tap = skip)
    → Menu ──TAP TO PLAY──→ Game ──dood──→ GameOver ──PLAY AGAIN──→ Game
        │                                      └──MAIN MENU──→ Menu
        └──SELECT SKIN──→ SkinSelect ──SELECT / BACK──→ Menu
```

## Swift → Godot mapping
| Swift | Godot |
|---|---|
| `SKScene` per scherm | Eén `.tscn` per scherm + `SceneRouter` autoload |
| `SKShapeNode` (alles is vector, geen sprites/textures) | `Node2D._draw()` met `draw_circle`, `draw_colored_polygon`, `draw_rect` |
| `update(_:)` per frame | `_physics_process` (vaste tick 60 Hz) — zie conventies |
| `SKAction` | `Tween` |
| `UserDefaults` | `ConfigFile` in `user://save.cfg` via `SaveManager` autoload |
| `AVAudioEngine` met gegenereerde sinus-buffers | `AudioStreamGenerator` of vooraf gerenderde `.wav` |
| `GoogleMobileAds` 13.3.0 + ATT | Godot AdMob-plugin (iOS) + ATT-plugin |
| `WKWebView` met inline SVG (studio-logo) | Geëxporteerde PNG(s) van het logo |
| Font `CourierNewPS-BoldMT` | Gebundelde monospace bold font (OFL, bv. Courier Prime Bold) |

## Conventies voor alle stories
1. **Coördinaten.** SpriteKit: y omhoog, oorsprong linksonder. Godot: y omlaag, oorsprong linksboven.
   In de stories zijn schermposities **al omgerekend naar Godot** (`y vanaf boven`), tenzij er "Swift:" bij staat.
   Bij tekencode van figuren (vis, vijanden): **keer het teken van elke y-waarde om**.
2. **Tijd.** Alle Swift-gameplaywaarden zijn **per frame** (bij 60 fps), niet per seconde. Port ze 1-op-1 in
   `_physics_process` met `physics/common/physics_ticks_per_second = 60`. Zo blijft het spelgevoel identiek en
   is het niet langer afhankelijk van 120 Hz-schermen (het origineel is dat wel).
3. **Referentieresolutie.** Swift gebruikt device points (bv. iPhone 15/16: 393×852). Kies viewport **393×852**,
   portrait, stretch `canvas_items` + `expand`; layout rekent met `get_viewport_rect().size`.
4. **Constanten** komen in één `Constants.gd` (autoload of `class_name`), niet verspreid door scripts.
5. **Kleuren** staan als `Color(r, g, b)` in Godot-notatie — direct te plakken.

## Bevindingen in de Swift-code (beslissen bij de rebuild)
| # | Bevinding | Advies |
|---|---|---|
| B1 | `OBSTACLE_WIDTH = 64` in Constants wordt nergens gebruikt; `Obstacle` hardcodet **80**. | Gebruik 80 (dat is wat spelers kennen), één constante. |
| B2 | "NEW BEST!" verschijnt ook bij gelijkspel en zelfs bij score 0 (vergelijking gebeurt ná opslaan, met `>=`). | Fix: alleen als `score > vorige best` en `score > 0`. Zie US-19. |
| B3 | Bewegende koraalzuilen zijn volledig gecodeerd maar hard uitgezet (`shouldMove = false`). | Niet porten in v1; optionele story US-26. |
| B4 | Diepte-label ("~ SHALLOW REEF ~" etc.) bestaat maar `setupDepthLabel()` wordt nooit aangeroepen. | Optionele story US-27. |
| B5 | Physics is frame-afhankelijk. | Opgelost door conventie 2. |
| B6 | Stekels en tentakels worden elk frame als nieuwe nodes aangemaakt/verwijderd. | In Godot gewoon `queue_redraw()` + `_draw()`. |
| B7 | Mute-icoon is een emoji (🔊/🔇). Godot rendert kleur-emoji niet betrouwbaar. | Icoon tekenen of als SVG/PNG. |
| B8 | Productie-AdMob-IDs staan hardcoded met `useTestAds = false`. | Test/prod schakelen via build-feature (`OS.is_debug_build()`). |
| B9 | **Highscore/skin van bestaande spelers staat in iOS `UserDefaults`.** Godot leest die niet. Als de Godot-build de bestaande App Store-app vervangt (zelfde bundle id), raken spelers hun voortgang kwijt. | US-25 (migratie). Beslis vóór release. |
| B10 | Dubbele, verouderde kopieën van `AdManager.swift`/`AppDelegate.swift` in `pufferfishrun.xcodeproj/`. | Negeren; de versies in de root van `swift_original/` zijn leidend. |
| B11 | `GameViewController.swift` (start direct GameScene, toont FPS) wordt niet gebruikt; de echte entry is `ContentView` → `StudioSplashScene`. | Negeren. |
| B12 | Haaientanden staan bij de staart i.p.v. de bek (`i * 7 - -30`). | Fixen in US-11. |
| B13 | Er is geen EU-consent (UMP) ondanks AdMob-gebruik in NL/EER. | Meenemen in US-22. |

## Backlog
Prioriteit: **M** = must (pariteit met v1.0), **S** = should, **C** = could. Omvang: S/M/L.

| ID | Story | Epic | Prio | Omvang | Afhankelijk van |
|---|---|---|---|---|---|
| [US-01](US-01-project-setup.md) | Project-setup, viewport, constanten | Fundament | M | S | – |
| [US-02](US-02-save-manager.md) | Voortgang opslaan (SaveManager) | Fundament | M | S | 01 |
| [US-03](US-03-scene-router.md) | Schermovergangen (SceneRouter) | Fundament | M | S | 01 |
| [US-04](US-04-pufferfish-besturing.md) | Kogelvis besturen (opblazen/zakken) | Gameplay | M | M | 01 |
| [US-05](US-05-pufferfish-visueel.md) | Kogelvis tekenen + animaties | Gameplay | M | M | 04 |
| [US-06](US-06-koraal-obstakels.md) | Koraalzuilen spawnen, bewegen, tekenen | Gameplay | M | L | 01 |
| [US-07](US-07-score-moeilijkheid.md) | Score + moeilijkheidscurve | Gameplay | M | S | 06 |
| [US-08](US-08-botsingen.md) | Botsingen en schermranden | Gameplay | M | S | 04, 06 |
| [US-09](US-09-vijand-systeem.md) | Vijand-spawner en basisgedrag | Gameplay | M | M | 08 |
| [US-10](US-10-vijand-kwal.md) | Vijand: kwal | Gameplay | M | S | 09 |
| [US-11](US-11-vijand-haai.md) | Vijand: haai | Gameplay | M | S | 09 |
| [US-12](US-12-vijand-zee-egel.md) | Vijand: zee-egel | Gameplay | M | S | 09 |
| [US-13](US-13-oceaan-achtergrond.md) | Oceaan-achtergrond en diepte-zones | Gameplay | M | M | 07 |
| [US-14](US-14-dood-sequentie.md) | Dood-animatie en overgang | Gameplay | M | S | 08, 03 |
| [US-15](US-15-studio-splash.md) | Studio-splash Digital Diamonds | Schermen | M | S | 03 |
| [US-16](US-16-game-splash.md) | Game-splash met titel | Schermen | M | M | 03, 05 |
| [US-17](US-17-hoofdmenu.md) | Hoofdmenu | Schermen | M | M | 02, 03 |
| [US-18](US-18-skin-selectie.md) | Skins kiezen en ontgrendelen | Schermen | M | L | 02, 05 |
| [US-19](US-19-game-over.md) | Game-over scherm met medailles | Schermen | M | M | 02, 14 |
| [US-20](US-20-geluidseffecten.md) | Geluidseffecten | Audio | M | S | 01 |
| [US-21](US-21-mute-knop.md) | Geluid aan/uit-knop | Audio | M | S | 02, 20 |
| [US-22](US-22-att-admob-init.md) | Tracking-toestemming + AdMob init | Monetisatie | M | M | 24 |
| [US-23](US-23-interstitial-ads.md) | Interstitial na elke 3e game | Monetisatie | M | S | 22, 19 |
| [US-24](US-24-ios-export.md) | iOS-export en App Store-config | Platform | M | M | 01 |
| [US-25](US-25-data-migratie.md) | Voortgang migreren uit Swift-versie | Platform | S | M | 02, 24 |
| [US-26](US-26-bewegende-obstakels.md) | Bewegende koraalzuilen (uitgezet in origineel) | Extra | C | S | 06 |
| [US-27](US-27-diepte-label.md) | Diepte-label per zone (nooit aangezet) | Extra | C | S | 13 |

**Voorgestelde volgorde:** 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 (= speelbare kern) → 13 → 14 → 09–12 → 17 → 19 → 18 → 15 → 16 → 20 → 21 → 24 → 22 → 23 → 25.

## Definition of Done (geldt voor elke story)
- Draait op een fysieke iPhone in portrait zonder fouten in de Godot-console.
- Gedrag naast de Swift-versie gelegd en gelijk bevonden (of afwijking bewust vastgelegd in de story).
- Waarden komen uit `Constants.gd`, geen magic numbers in scene-scripts.
- 60 fps stabiel op het oudste ondersteunde toestel.
