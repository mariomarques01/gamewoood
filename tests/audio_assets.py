"""Signal integrity of shipped media, independent of game playback implementation."""
from pathlib import Path
import hashlib
import json
import math
import struct
import wave

root = Path('assets/audio')
manifest = json.loads((root / 'manifest.json').read_text())
assert len(manifest) == 17
assert sum((root / name).stat().st_size for name in manifest) < 2_500_000
for name, info in manifest.items():
    path = root / name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == info['sha256'], name
    if path.suffix == '.ogg':
        assert path.read_bytes().startswith(b'OggS'), name
        continue
    with wave.open(str(path)) as source:
        assert source.getframerate() == 44100 and source.getnchannels() == 1
        assert source.getsampwidth() == 2
        data = source.readframes(source.getnframes())
    samples = struct.unpack('<' + 'h' * (len(data) // 2), data)
    assert len(samples) >= 3000 and any(samples), name
    peak = max(abs(value) for value in samples) / 32768
    rms = math.sqrt(sum(value * value for value in samples) / len(samples)) / 32768
    assert 0.001 < rms < 0.5 and peak < 0.71, (name, rms, peak)
    assert samples[0] == 0 and samples[-1] == 0, ('Hard sample edge', name)
assert len({manifest['sfx/' + name + '.wav']['sha256'] for name in ('shot_a', 'shot_b', 'shot_c')}) == 3
print('AUDIO_ASSETS_OK 17 licensed files, real signal, peak headroom, silent edges, distinct shots')
