# HUD artwork

`reference-atlas.png` is transparent raster artwork generated for the user-supplied
HUD reference in `tests/references/hud-target.jpg`. The atlas contains portrait,
heart, coin, crate, settings, joystick pieces, jump/swap controls, gun, lightning,
blank metal panel, health fill, energy segment and an empty level badge.

`atlas-regions.json` describes the nontransparent content bounds of each asset in
actual atlas pixels. Godot uses AtlasTexture regions; the atlas itself is not
resampled or split. All numbers, state labels and progress remain live game UI.
The generated portrait badge displays the current run's Fury level.
