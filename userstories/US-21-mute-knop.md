# US-21 — Geluid aan/uit-knop
**Epic:** Audio · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** het geluid op elk moment uit en aan kunnen zetten, **zodat** ik ook in stille omgevingen kan spelen.

## Context (Swift — `SoundButton.swift`)
- Ronde knop rechtsonder op (w−50, h−50) in **Menu, Game en GameOver** (niet in splash/skinselect).
- Zwarte cirkel r30, vulling `UI_BLUE` r27 met 2 px zwarte rand, icoon 22 pt (🔊 / 🔇).
- Tik: knop schaalt 0.88 → 1.0 (2× 0.08 s), toggle `is_muted`, icoon wisselt. Instelling persistent.
- Mute zet het master-volume op 0.

## Acceptatiecriteria
- [ ] Herbruikbare `SoundButton` scene, op een `CanvasLayer` boven de game.
- [ ] Iconen als SVG/PNG (speaker / speaker-met-kruis) i.p.v. emoji (bevinding B7).
- [ ] `AudioServer.set_bus_mute(master, is_muted)` + opslaan via `SaveManager`.
- [ ] In de game-scene: tik op de knop wordt **niet** doorgegeven als opblaas-input (`accept_event()` / `mouse_filter = STOP` en gameplay-input via `_unhandled_input`).
- [ ] Hitarea minimaal 60×60 pt.
