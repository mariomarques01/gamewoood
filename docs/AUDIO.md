# v0.8.0 — quiet soundtrack and curated effects

## Sound direction and assets

The brief asks for restrained, pleasant audio rather than harsh/repetitive bleeps.
This release uses real edited samples: Kenney's CC0 Sci-Fi Sounds for effects and
SRG774's CC0 ambient track Sector for music. The optional generation service required
reauthentication; it created no task. The deliverable does not depend on that service.
Source links, names, licenses and delivered SHA-256 hashes are in
[assets/audio/CREDITS.md](../assets/audio/CREDITS.md) and manifest.json.

Music is a stereo ambient bed, about 55 seconds, with a two-second wrap crossfade
and seamless Ogg looping. It defaults to 22% and sits under the effects. SFX default
to 70%. Samples were EQ'd to reduce rumble/harsh highs, given soft edges, and
conditioned toward -20 LUFS / -4 dBTP before per-event mixing gains. Final PCM
edges are explicitly zero. The shipped pack is about 1.4 MB, without external media
requests while playing. These are edited licensed recordings, not placeholder
square waves or a claim of an original composition.

## Mixer and lifecycle

AudioDirector is one persistent autoload with Music, Effects and UI buses under
its own master/limiter. Twelve effect players are shared, with event rate limits,
priority, subtle pitch variation and distance attenuation; three blaster variants
rotate. This prevents rapid fire, pickups and simultaneous deaths from piling up
without bounds. Music streams separately, fades in/out, ducks by 9 dB in manual
pause, suspends for portrait/background, and is not duplicated on restart.

All players use stream playback in Godot 4.3 so the bus controls/limiter also apply
on Web. AudioApi resolves the autoload at runtime, including standalone SceneTree
tests, rather than relying on globals binding before preloaded test scripts.
Explicit test shutdown frees players and gives the audio thread time to release
playback references before quitting; Godot error logs are not suppressed.

Combat cues cover blaster, plasma, impact, alien burst/splatter, hurt, reload,
jump/steps, pickups, mission, victory/defeat and pause UI. Healing does not trigger
the damage cue. Audio is activated by an actual input gesture on Web; blocked sounds
are discarded rather than queued to burst later. Music/effects sliders and mute
are in pause, with explicit native touch routing. Preferences save separately to
user://deadlight_audio.cfg so progress saves cannot overwrite them.

## Verification and limits

- audio_assets.py checks all 17 hashes, real signal, peak headroom, zero PCM edges,
  sample rate/channels, three distinct shots and asset-size budget.
- audio_smoke.gd checks real resources/loop, voice throttling, pause/UI, mute,
  background focus, saved preferences, one mixer across restart and shutdown.
- Browser checks instrument the actual Web Audio output to require a nonzero signal
  after gesture, zero output when muted, and touchscreen/mouse volume controls.
  This checks the exported audio graph, not just .playing flags or file existence.
- Existing combat, missions, stress, rotation, three-pointer jump and deployment
  validation remain required.

Speaker/headphone taste, hardware volume, physical iPhone/Safari interruption and
silent-switch behavior still require real-device listening. Automated signal checks
cannot certify subjective sound quality or the physical speaker output.
