"""Verify install metadata and real offline game startup under a Pages subpath."""
import argparse
import functools
import http.server
import json
import os
from pathlib import Path
import threading
import tempfile
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory', required=True)
args = parser.parse_args()
directory = Path(args.directory).resolve()
# Serve the export under its directory name, never only at the origin root.
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(directory.parent))
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f'http://127.0.0.1:{server.server_port}/{directory.name}/'
try:
    with tempfile.TemporaryDirectory(prefix="deadlight-pwa-") as profile, sync_playwright() as p:
        context = p.chromium.launch_persistent_context(profile,
            viewport={"width": 640, "height": 360},
            executable_path=os.environ.get('CHROMIUM_BIN'),
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        page = context.new_page()
        messages, errors = [], []
        page.on('console', lambda msg: messages.append(msg.text))
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.goto(url, wait_until='networkidle', timeout=120000)
        page.wait_for_function("document.querySelector('link[rel=manifest]') !== null")
        manifest = page.evaluate("async () => (await fetch(document.querySelector('link[rel=manifest]').href)).json()")
        assert manifest['display'] == 'standalone', manifest
        assert manifest['orientation'] == 'landscape', manifest
        assert manifest['scope'] == './', manifest
        assert {'192x192', '512x512'} <= {i['sizes'] for i in manifest['icons']}
        assert page.evaluate('async icons => (await Promise.all(icons.map(async i => (await fetch(i.src)).ok))).every(Boolean)', manifest['icons'])
        page.evaluate('async () => { await navigator.serviceWorker.ready; }')
        page.wait_for_function("async () => !!(await caches.match('index.wasm')) && !!(await caches.match('index.pck'))", timeout=120000)
        # Get controlled even when the first visit was not controlled by the SW.
        page.reload(wait_until='networkidle', timeout=120000)
        page.wait_for_function('navigator.serviceWorker.controller !== null')
        page.wait_for_function("() => document.querySelector('canvas') !== null")
        session = context.new_cdp_session(page)
        installability = session.send('Page.getInstallabilityErrors')
        assert not installability['installabilityErrors'], installability
        context.set_offline(True)
        for target in (url, url + 'index.html'):
            messages.clear()
            response = page.goto(target, wait_until='load', timeout=120000)
            assert response.ok
            for _ in range(240):
                if any('DEADLIGHT_READY district=1 version=0.10.0' in m for m in messages):
                    break
                page.wait_for_timeout(250)
            assert any('DEADLIGHT_READY district=1 version=0.10.0' in m for m in messages), messages
            assert page.locator('canvas').is_visible()
        assert not errors, errors
        Path('build/logs').mkdir(parents=True, exist_ok=True)
        Path('build/logs/pwa.json').write_text(json.dumps({'manifest': manifest, 'installability': installability,
            'offline_startup': ['directory', 'index.html']}, indent=2))
        context.close()
        print('WEB_PWA_OK installable; actual game starts offline at directory and index.html')
finally:
    server.shutdown()
