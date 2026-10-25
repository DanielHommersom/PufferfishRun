# Font

`game_font.tres` is a `SystemFont` that resolves to **Courier New Bold** — the exact font of the
Swift version (`CourierNewPS-BoldMT`). Courier New ships with iOS and macOS, so nothing has to be
bundled and there is no licensing issue.

If you want a guaranteed-identical look on every platform (Android/Linux have no Courier New), drop
`CourierPrime-Bold.ttf` (OFL, https://fonts.google.com/specimen/Courier+Prime) into this folder and
point `game_theme.tres` / `Constants.FONT_PATH` at it.
