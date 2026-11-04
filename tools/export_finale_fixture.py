"""Export a separate Web QA fixture using the actual game code; never ship test hooks."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
output = root / 'build/web-finale'
output.mkdir(parents=True, exist_ok=True)
log_path = root / 'build/logs/finale-export.log'
godot = os.environ.get('GODOT_BIN', 'godot')
with tempfile.TemporaryDirectory(prefix='deadlight-finale-') as temporary:
    staging = Path(temporary)
    for name in ('assets', 'resources', 'scenes', 'scripts'):
        shutil.copytree(root / name, staging / name)
    (staging / 'tests').mkdir()
    for name in ('web_finale_fixture.gd', 'web_finale_fixture.tscn'):
        shutil.copy2(root / 'tests' / name, staging / 'tests' / name)
    project = (root / 'project.godot').read_text().replace('res://scenes/main.tscn', 'res://tests/web_finale_fixture.tscn')
    (staging / 'project.godot').write_text(project)
    presets = (root / 'export_presets.cfg').read_text().replace('tests/*,', '')
    (staging / 'export_presets.cfg').write_text(presets)
    commands = [
        [godot, '--headless', '--editor', '--path', str(staging), '--import'],
        [godot, '--headless', '--path', str(staging), '--export-release', 'Web', str(output / 'index.html')],
    ]
    with log_path.open('w') as log:
        for command in commands:
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            log.write(result.stdout)
            if result.returncode or 'SCRIPT ERROR:' in result.stdout or any(line.startswith('ERROR:') for line in result.stdout.splitlines()):
                print(f'Failed Godot command: {command}', file=sys.stderr)
                print(result.stdout, file=sys.stderr)
                raise SystemExit(f'Finale fixture export failed; see {log_path}')
subprocess.run([sys.executable, str(root / 'tools/prepare_pwa.py'), str(output)], check=True)
print('FINALE_FIXTURE_EXPORT_OK isolated production code and real mission/result logic')
