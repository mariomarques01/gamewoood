"""Run the actual Web export; fail on browser or Godot errors and missing startup."""
import argparse
import functools
import http.server
import json
import os
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory')
parser.add_argument('--url')
args = parser.parse_args()
server = None
if args.directory:
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.directory)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f'http://127.0.0.1:{server.server_port}/'
else:
    url = args.url
assert url, 'Supply --directory or --url'
Path('build/logs').mkdir(parents=True, exist_ok=True)
try:
    with sync_playwright() as playwright:
        executable = os.environ.get('CHROMIUM_BIN')
        browser = playwright.chromium.launch(
            executable_path=executable,
            args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        for name, size, mobile in [('desktop', {'width': 1280, 'height': 720}, False),
                                   ('mobile', {'width': 844, 'height': 390}, True)]:
            context = browser.new_context(viewport=size, is_mobile=mobile, has_touch=mobile)
            page = context.new_page()
            messages, errors = [], []
            page.on('console', lambda msg: messages.append(msg.text))
            page.on('pageerror', lambda error: errors.append(str(error)))
            response = page.goto(url, wait_until='networkidle', timeout=120000)
            assert response.ok, response.status
            # A printed sentinel originates in the executed GDScript, not the HTML shell.
            for _ in range(120):
                if any('DEADLIGHT_READY district=1 version=0.2.2' in line for line in messages):
                    break
                page.wait_for_timeout(500)
            assert any('DEADLIGHT_READY district=1 version=0.2.2' in line for line in messages), messages
            page.wait_for_timeout(2000)
            page.screenshot(path=f'build/logs/{name}.png')
            errors += [line for line in messages if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')]
            Path(f'build/logs/{name}-console.json').write_text(json.dumps(messages, indent=2))
            assert not errors, errors
            assert page.locator('canvas').is_visible()
            print(f'WEB_SMOKE_OK {name} {url}')
            context.close()
        browser.close()
finally:
    if server:
        server.shutdown()
