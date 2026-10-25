# US-24 — iOS-export en App Store-configuratie
**Epic:** Platform · **Prio:** Must · **Omvang:** M

**Als** studio-eigenaar **wil ik** de Godot-build als update van de bestaande app kunnen uitbrengen, **zodat** bestaande spelers de nieuwe versie automatisch krijgen.

## Context (Swift-project)
| Instelling | Waarde |
|---|---|
| Bundle ID | `digitaldiamonds.pufferfishrun` |
| Display name | Pufferfish Run |
| Versie / build | 1.0 / 1 |
| Deployment target | iOS 26.2 (erg hoog — sluit oudere toestellen uit) |
| Oriëntatie | alleen portrait, `UIRequiresFullScreen` |
| Statusbalk | verborgen |
| App-icoon | `Assets.xcassets/AppIcon.appiconset/icon.jpg` |
| Privacy policy / support | `docs/index.html`, `docs/support/index.html` (GitHub Pages, contact `digitaldiamonds.ai@gmail.com`) |

## Acceptatiecriteria
- [ ] iOS-exportpreset met **zelfde bundle ID**, versie **≥ 1.1** (hoger dan de live versie), build-nummer oplopend.
- [ ] Portrait-only, statusbalk verborgen, fullscreen; safe-area respecteren voor score-label en mute-knop (notch / Dynamic Island / home-indicator).
- [ ] App-icoon 1024×1024 vanuit `icon.jpg` (zonder alpha) in de exportpreset.
- [ ] Launch-screen in `(0.06, 0.04, 0.10)` zodat het naadloos overgaat in de studio-splash.
- [ ] Minimum iOS-versie bewust kiezen (advies: wat Godot 4.7 minimaal ondersteunt, i.p.v. 26.2) — groter bereik.
- [ ] AdMob- en ATT-plists uit US-22 in de preset.
- [ ] Privacy policy (`docs/index.html`) nalopen: klopt de tekst nog met de Godot-build en de plugin-SDK's?
- [ ] TestFlight-build draait op minstens één oud en één nieuw toestel.

## Notities
- Godot-builds zijn groter dan een SpriteKit-app (engine ±30–40 MB). Bestaande spelers merken dat in de update-grootte.
