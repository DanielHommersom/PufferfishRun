# US-25 — Voortgang migreren uit de Swift-versie
**Epic:** Platform · **Prio:** Should (Must als de Godot-build de bestaande App Store-app vervangt) · **Omvang:** M

**Als** bestaande speler **wil ik** na de update mijn highscore, ontgrendelde skins en geluidsinstelling behouden, **zodat** ik niet opnieuw hoef te beginnen.

## Probleem
De Swift-versie bewaart alles in `NSUserDefaults` (keys `highScore`, `selectedSkin`, `isMuted`, standaard-suite). Godot schrijft naar `user://` en leest `UserDefaults` niet. Zonder migratie start iedereen weer op 0 en verliest zijn skins (skins zijn puur afgeleid van `highScore`).

## Acceptatiecriteria
- [ ] Kleine iOS-plugin (GDExtension of Godot iOS-plugin in Obj-C/Swift) met één methode `read_legacy_defaults() -> Dictionary` die de drie keys uit `NSUserDefaults.standardUserDefaults` leest.
- [ ] Bij eerste start van de Godot-build (`SaveManager`: geen `user://save.cfg` én vlag `migrated` ontbreekt): legacy-waarden overnemen, opslaan, vlag `migrated = true` zetten.
- [ ] Migratie draait precies één keer; daarna is `save.cfg` leidend.
- [ ] Getest door: Swift-versie installeren via Xcode, score ≥ 20 halen en een skin kiezen, daarna Godot-build eroverheen installeren (zelfde bundle ID) → score en skin zijn behouden.
- [ ] Op andere platforms is de migratie een no-op.

## Beslissing nodig
Als de Godot-versie als **nieuwe app** (nieuw bundle ID) uitkomt, vervalt deze story.
