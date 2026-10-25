# US-20 — Geluidseffecten
**Epic:** Audio · **Prio:** Must · **Omvang:** S

**Als** speler **wil ik** hoorbare feedback bij opblazen en doodgaan, **zodat** de besturing en het moment van falen duidelijker voelen.

## Context (Swift — `SoundManager.swift`)
Geen audiobestanden: beide geluiden worden **wiskundig gegenereerd** (sinus met exponentiële envelope), via één `AVAudioPlayerNode` — een nieuw geluid stopt het vorige.

| Geluid | Duur | Frequentie | Envelope | Volume | Formule |
|---|---|---|---|---|---|
| Inflate | 0.12 s | 300 → 800 Hz lineair | `exp(-t * 18)` | 0.6 | `sin(2π·f·t) · env · 0.6` |
| Game over | 0.6 s | 500 → 150 Hz lineair | `exp(-t * 3.5)` | 0.5 | `(sin(2π·f·t) + 0.3·sin(2π·1.5f·t)) · env · 0.5` |

(`f` = momentane frequentie op tijd `t`; het origineel gebruikt `sin(2π·f(t)·t)`, niet fase-geïntegreerd — dat geeft een iets steilere chirp dan de getallen suggereren. Reproduceer exact dezelfde formule voor gelijk geluid.)

## Acceptatiecriteria
- [ ] Autoload `SoundManager` met `play_inflate()` en `play_game_over()`.
- [ ] **Aanpak (advies):** genereer beide als `AudioStreamWAV` bij opstarten (44.1 kHz, 16-bit mono) met bovenstaande formules in GDScript, of render ze één keer offline naar `assets/audio/inflate.wav` en `gameover.wav`. Eenvoudiger en betrouwbaarder op iOS dan `AudioStreamGenerator`.
- [ ] Eén `AudioStreamPlayer` op een `SFX`-bus: nieuw geluid onderbreekt het vorige (pariteit).
- [ ] Inflate speelt alleen bij het begin van een druk (niet herhaald tijdens vasthouden); game over speelt bij de eerste hit.
- [ ] Respecteert mute (US-21).
- [ ] iOS: audio-sessie zo instellen dat muziek van de gebruiker (Spotify e.d.) **niet** stopt — Godot project setting `audio/general/ios/session_category = Ambient` (controleer de exacte setting-naam in 4.7).
