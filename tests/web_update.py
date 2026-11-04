"""An installed PWA must fetch a new bundle despite fresh browser HTTP cache."""
import argparse
import http.server
from pathlib import Path
import re
import shutil
import tempfile
import threading
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory', default='build/web')
args = parser.parse_args()
current = Path(args.directory).resolve()
with tempfile.TemporaryDirectory(prefix='deadlight-update-') as temporary:
    previous = Path(temporary) / 'previous'
    snapshot = Path(temporary) / 'current'
    shutil.copytree(current, snapshot)
    current = snapshot
    shutil.copytree(current, previous)
    bundle = previous / 'index.js'
    bundle.write_text('window.__previous_bundle = true;\n' + bundle.read_text())
    worker = previous / 'index.service.worker.js'
    worker.write_text(re.sub(r"const CACHE_VERSION = '[^']+';", "const CACHE_VERSION = 'previous-test-release';", worker.read_text()))
    state = {'directory': previous}

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(state['directory']), **kw)
        def do_GET(self):
            # Simulate a deployment with fresh content, irrespective of copied mtimes.
            if 'If-Modified-Since' in self.headers:
                del self.headers['If-Modified-Since']
            super().do_GET()
        def log_message(self, *_args):
            pass
        def end_headers(self):
            self.send_header('Cache-Control', 'no-cache' if 'service.worker.js' in self.path else 'public, max-age=3600')
            super().end_headers()

    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
            context = browser.new_context(viewport={'width': 844, 'height': 390}, is_mobile=True, has_touch=True)
            page = context.new_page()
            page.goto(f'http://127.0.0.1:{server.server_port}/', wait_until='load')
            page.wait_for_function('!!window.__previous_bundle', timeout=120000)
            page.wait_for_function('!!navigator.serviceWorker.controller', timeout=120000)
            page.evaluate("localStorage.setItem('upgrade-preserved', 'yes')")
            print('PWA_PREVIOUS_ACTIVE',flush=True)
            state['directory'] = current
            page.evaluate('async () => { const registration = await navigator.serviceWorker.getRegistration(); await registration.update(); }')
            page.wait_for_function("async () => { const r = await navigator.serviceWorker.getRegistration(); const keys = await caches.keys(); return !r.installing && keys.some(k => !k.endsWith('previous-test-release')); }", timeout=120000)
            print('PWA_NEW_CACHE_READY',flush=True)
            page.evaluate("async () => { const registration = await navigator.serviceWorker.getRegistration(); if (registration.waiting) registration.waiting.postMessage('update'); else location.reload(); }")
            page.wait_for_function('!window.__previous_bundle && !!navigator.serviceWorker.controller', timeout=120000)
            assert page.evaluate("localStorage.getItem('upgrade-preserved')") == 'yes'
            cached = page.evaluate("async () => await (await caches.match('index.js')).text()")
            assert '__previous_bundle' not in cached, 'PWA installed stale HTTP-cached engine code'
            context.set_offline(True)
            page.reload(wait_until='load')
            page.wait_for_function('!!window.Engine', timeout=120000)
            assert not page.evaluate('!!window.__previous_bundle')
            assert page.evaluate("localStorage.getItem('upgrade-preserved')") == 'yes'
            print('WEB_UPDATE_OK fresh bundle replaces installed PWA; origin data preserved; new bundle loads offline')
            browser.close()
    finally:
        server.shutdown()
