# Audio credits and licenses — 0.12.0

## Music

**Battle of the Void (Loop)**, from *Action Music Pack*, by **Marcelo Fernandez**.
https://www.marcelofernandezmusic.com/
https://opengameart.org/content/action-music-pack

Licensed under **Creative Commons Attribution 4.0 International**, as specified
in the author's Copyright/Attribution Notice on the source page:
https://creativecommons.org/licenses/by/4.0/

Adaptation: stereo 44.1 kHz Vorbis, loudness conditioned to -18 LUFS / -3 dBTP.
The original 158.35-second musical loop is preserved; this is an attributed
licensed composition, not music authored by this project.
Delivered file: `music/combat_patrol.ogg`.

## Recorded firearms

**The Free Firearm Sound Library**, by **Ben Jaszczak, Brian Nelson,
Kevin Heras, and Matthew Nanney**, **CC0 1.0 / Public Domain**.
https://opengameart.org/content/the-free-firearm-sound-library
https://creativecommons.org/publicdomain/zero/1.0/

Pistol: three excerpts of **1911 .45 pistol** recordings `A_42P.wav` and
`A_34P.wav`. Machine gun: three individual shots from **Carl Gustav M45 9mm
submachine gun**, `G_20P.wav`. The firearm identities come from the original
`Prepared Master Sheet.csv`. These replace the former laser samples.
Adaptations: separate shot extraction, EQ, mono 44.1 kHz PCM, DC removal,
peak normalization and short edge fades. No synthesized firearm reports.
Delivered files: `sfx/shot_[abc].wav`, `sfx/machine_[abc].wav`.

**Handgun Reload Sound Effect**, by **zer0_sol**, **CC0 1.0**.
https://opengameart.org/content/handgun-reload-sound-effect

Recorded magazine removal/insertion and slide action, arranged at separate
speeds to match the pistol's 0.9s and machine gun's 1.2s reload animations.
These are game adaptations of one magazine/slide recording, not a claim of
separate field recordings of the two weapon models.
Delivered files: `sfx/pistol_reload.wav`, `sfx/machine_reload.wav`.

## Alien voices

**15 monster grunt/pain/death sounds**, by **Michel Baradari**,
**Creative Commons Attribution 3.0 Unported**.
https://opengameart.org/content/15-monster-gruntpaindeath-sounds
https://creativecommons.org/licenses/by/3.0/

Sources: `grunt1.wav`, `grunt2.wav`, `piggrunt1.wav`, `painr.wav`,
`deathb.wav`, `deathr.wav`. Adaptations: EQ, mono conversion, peak conditioning
and edge fades. Delivered files: `sfx/alien_*.wav`.

## Retained effects

Kenney, **Sci-Fi Sounds (1.0)**, **CC0 1.0**.
https://kenney.nl/assets/sci-fi-sounds
https://opengameart.org/content/sci-fi-sounds
Original license: `KENNEY-LICENSE.txt`.

Retained for plasma, impacts, explosions, splatter, movement and UI cues.
The former Sector soundtrack and generic door-close reload are removed.

`manifest.json` records each delivered file's source, processing and SHA-256.
Credits are also displayed in the game's audio settings. License texts are
included in this directory and in exported builds.
