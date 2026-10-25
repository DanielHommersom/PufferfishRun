# US-18 — Skins kiezen en ontgrendelen
**Epic:** Schermen · **Prio:** Must · **Omvang:** L

**Als** speler **wil ik** nieuwe kleuren voor mijn vis vrijspelen door hogere scores te halen, **zodat** ik een reden heb om mijn record te verbeteren.

## Skin-data (Swift — `SkinDefinition.swift`)
| id | Naam | Unlock (best ≥) | body | belly | spine | eye | tail |
|---|---|---|---|---|---|---|---|
| default | PUFFERFISH | 0 | (0.957,0.659,0.196) | (0.941,0.471,0.125) | (1.0,0.976,0.902) | (0.290,0.565,0.851) | (0.957,0.573,0.102) |
| ghost | GHOST | 10 | (0.863,0.910,0.941) | (0.722,0.816,0.878) | (1,1,1) | (1.0,0.267,0.267) | (0.784,0.863,0.910) |
| lava | LAVA | 20 | (0.910,0.251,0.125) | (0.753,0.125,0.063) | (1.0,0.667,0.0) | (1,1,0) | (0.753,0.188,0.063) |
| ocean | DEEP SEA | 35 | (0.102,0.416,0.667) | (0.051,0.290,0.478) | (0.533,0.867,1.0) | (0.0,1.0,0.667) | (0.051,0.290,0.478) |
| gold | GOLDEN | 50 | (0.969,0.761,0.204) | (0.878,0.627,0.125) | (1.0,0.980,0.800) | (1.0,0.400,0.0) | (0.878,0.627,0.125) |
| shadow | SHADOW | 75 | (0.102,0.102,0.180) | (0.051,0.051,0.102) | (0.608,0.349,0.714) | (0.608,0.349,0.714) | (0.051,0.051,0.102) |

> `belly` wordt in de Swift-code nergens gebruikt (de buik is altijd body − 0.15). Meenemen in de data, niet in de rendering — of bewust gaan gebruiken.

## Scherm (Swift — `SkinSelectScene.swift`)
- Donkere overlay 65% zwart over `OCEAN_TOP`.
- Paneel: breedte `w − 40`, hoogte 560, verticaal gecentreerd, `PANEL_BG`, 3 px zwarte rand, radius 20.
- Titel "SELECT SKIN" 18 pt (44 px onder paneeltop), "BEST: n" 11 pt `UI_GOLD_TEXT` (68 px onder top).
- **Grid** 3 kolommen, kaartjes 80×110, 12 px tussenruimte, gecentreerd; eerste rij begint 90 px onder de paneeltop.
  - Ontgrendeld: mini-vis (r 22, 6 stekels, 2 px outlines).
  - Vergrendeld: donker silhouet `(0.1,0.1,0.15)` met "?" `(0.2,0.3,0.4)`.
  - Onderaan: "FREE" of unlock-score (7 pt), groen `UI_GREEN` als ontgrendeld, anders oranje `(1.0,0.533,0.0)`.
  - Voortgangsbalk 3 px onder in het kaartje: `min(best / unlock, 1)`, groen bij 100%, anders oranje.
  - Geselecteerd kaartje: rand `UI_ORANGE`, vulling `UI_BLUE`; anders zwarte rand, vulling `(0.024,0.078,0.125)`.
- Onder het grid: naam (14 pt; wit of `UI_MUTED_TEXT` als vergrendeld) en status "UNLOCKED" (groen) of "REACH SCORE n" (oranje).
- Knop 240×56: "SELECT" groen of "LOCKED" grijs `(0.2,0.2,0.2)`.
- "< BACK" 13 pt `UI_MUTED_TEXT` onderaan het paneel.

## Acceptatiecriteria
- [ ] Skins als `Resource` (`SkinDefinition.gd`) + één `skins.tres`/array — makkelijk uitbreidbaar.
- [ ] Tik op kaartje → selectie verplaatst (ook vergrendelde kaartjes mogen geselecteerd worden om de eis te zien).
- [ ] SELECT bij ontgrendeld: knop schaalt 0.94 → 1.0 (2× 0.08 s), skin opslaan, moveIn-down naar Menu. Bij vergrendeld: niets.
- [ ] BACK → moveIn-down naar Menu zonder op te slaan.
- [ ] Bij openen staat de huidige skin geselecteerd.
- [ ] Grid schaalt mee als er later >6 skins komen (scrollbaar of extra rijen binnen het paneel).
