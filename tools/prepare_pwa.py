"""Complete Godot 4.3's PWA export, including offline directory navigation."""
import json
import re
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parents[1]
output = Path(sys.argv[1] if len(sys.argv) > 1 else root / 'build/web')
manifest_path = output / 'index.manifest.json'
manifest = json.loads(manifest_path.read_text())
manifest.update(id='./', scope='./', short_name='DEADLIGHT', lang='pt-BR',
                description='Defenda a base costeira com o Capitão Tranco.',
                theme_color='#10252f')
shutil.copyfile(root / 'assets/pwa/icon-192.png', output / 'index.192x192.png')
manifest['icons'] = [icon for icon in manifest['icons'] if icon['src'] != 'index.192x192.png']
manifest['icons'].append({'src': 'index.192x192.png', 'sizes': '192x192', 'type': 'image/png'})
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
worker_path = output / 'index.service.worker.js'
worker = worker_path.read_text()
# The 4.3 exporter lists a thread worker even for thread_support=false.
# Missing optional files would reject addAll and prevent SW installation.
for constant in ('CACHED_FILES', 'CACHABLE_FILES'):
    pattern = rf'const {constant} = (\[.*?\]);'
    match = re.search(pattern, worker)
    if match is None:
        raise RuntimeError(f'Unsupported Godot worker: missing {constant}')
    files = [name for name in json.loads(match[1]) if (output / name).is_file()]
    if constant == 'CACHED_FILES' and 'index.png' not in files:
        files.append('index.png')
    worker = re.sub(pattern, f'const {constant} = {json.dumps(files)};', worker)
# Cache the complete game atomically. The first uncontrolled page also downloads
# WASM/PCK, so on-demand caching alone cannot guarantee offline play after it loads.
worker = worker.replace('cache.addAll(CACHED_FILES)',
    "cache.addAll(FULL_CACHE.concat(['index.manifest.json', 'index.192x192.png', "
    "'index.144x144.png', 'index.180x180.png', 'index.512x512.png']))")
# Navigation preload is optional; failure must not reject SW activation.
worker = worker.replace('self.registration.navigationPreload.enable()',
                        'self.registration.navigationPreload.enable().catch(() => {})')
worker = worker.replace(
    "return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable().catch(() => {}) : Promise.resolve();",
    "return (('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable().catch(() => {}) : Promise.resolve()).then(() => self.clients.claim());")
# GitHub Pages launches /gamewoood/; Godot only caches index.html by default.
worker = worker.replace('let cached = await cache.match(event.request);',
    'let cached = await cache.match(event.request);\n'
    '\t\t\t\tif (!cached && isNavigate) cached = await cache.match(CACHED_FILES[0]);')
worker_path.write_text(worker)
print('PWA_EXPORT_OK manifest, install icons, complete offline cache')
