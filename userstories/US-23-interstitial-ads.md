# US-23 — Interstitial na elke 3e game
**Epic:** Monetisatie · **Prio:** Must · **Omvang:** S

**Als** studio-eigenaar **wil ik** na elke derde game over een interstitial tonen, **zodat** de game inkomsten oplevert zonder spelers na elk potje te storen.

## Context (Swift — `AdManager.swift`)
- Interstitial ad unit (prod): `ca-app-pub-3366446717708247/8765817424`. Test: `ca-app-pub-3940256099942544/4411468910`.
- Laden bij start; bij fout opnieuw na `attempts` seconden, max 3 pogingen; teller reset bij succes.
- `on_player_died()` (aangeroepen bij openen GameOver): `games_since_ad += 1`; bij ≥ 3 → tonen als geladen en teller op 0; als niet geladen → opnieuw laden **en teller toch op 0** (voorkomt spam).
- Na sluiten of tonen-mislukt → volgende ad laden.
- Teller is **niet** persistent (reset bij app-herstart).

## Acceptatiecriteria
- [ ] Autoload `AdManager` met exact deze logica en constanten (`GAMES_BEFORE_AD = 3`, `MAX_LOAD_ATTEMPTS = 3`).
- [ ] Ad verschijnt over het GameOver-scherm; na sluiten is GameOver gewoon bedienbaar.
- [ ] Audio wordt gepauzeerd tijdens de ad en hervat erna.
- [ ] Op niet-iOS-platforms (editor, desktop) is AdManager een no-op met log-regels.
- [ ] Logging alleen in debug-builds (origineel logt met emoji naar console in productie).
