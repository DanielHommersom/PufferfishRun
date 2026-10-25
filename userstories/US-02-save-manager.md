# US-02 — Voortgang opslaan (SaveManager)
**Epic:** Fundament · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** dat mijn beste score, gekozen skin en geluidsinstelling bewaard blijven, **zodat** ik na herstarten verder ga waar ik was.

## Context (Swift)
`UserDefaults` met drie keys:
| Key | Type | Default | Gebruikt in |
|---|---|---|---|
| `highScore` | Int | 0 | Menu, SkinSelect, GameOver |
| `selectedSkin` | String | `"default"` | Game, Menu, SkinSelect |
| `isMuted` | Bool | false | SoundManager, SoundButton |

## Acceptatiecriteria
- [ ] Autoload `SaveManager` met properties `high_score: int`, `selected_skin: String`, `is_muted: bool`.
- [ ] Opslag in `user://save.cfg` (`ConfigFile`), sectie `progress` en `settings`. Zelfde key-namen als Swift (vergemakkelijkt US-25).
- [ ] Laden bij `_ready()`; ontbrekend bestand → defaults.
- [ ] Schrijven direct bij elke wijziging (setter), niet pas bij afsluiten (iOS kan de app zonder notificatie killen).
- [ ] `submit_score(score) -> bool` slaat alleen op als `score > high_score` en retourneert of het een nieuw record is.
- [ ] Signal `high_score_changed`, `skin_changed`, `mute_changed`.
- [ ] Onbekende `selected_skin` (bv. verwijderde skin) valt terug op `"default"`.

## Notities
- Swift slaat ook op bij gelijke score (`>=`); functioneel geen verschil, maar `>` is de juiste basis voor de "NEW BEST!"-fix (US-19).
