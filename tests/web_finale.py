"""Render the real completion UI and replay in WebGL using the isolated QA export."""
import argparse
import functools
import http.server
import json
import os
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory', required=True)
args = parser.parse_args()
Path('build/logs').mkdir(parents=True, exist_ok=True)
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=os.environ.get('CHROMIUM_BIN'), args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        context = browser.new_context(viewport={'width': 844, 'height': 390}, is_mobile=True, has_touch=True)
        page = context.new_page()
        messages, errors = [], []
        page.on('console', lambda message: messages.append(message.text))
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.goto(f'http://127.0.0.1:{server.server_port}/', wait_until='networkidle', timeout=120000)
        for _ in range(240):
            if any('DEADLIGHT_WEB_FINALE_FIXTURE ' in line for line in messages):
                break
            page.wait_for_timeout(250)
        fixture = next((line.split('DEADLIGHT_WEB_FINALE_FIXTURE ', 1)[1] for line in messages if 'DEADLIGHT_WEB_FINALE_FIXTURE ' in line), None)
        assert fixture, messages
        info = json.loads(fixture)
        assert info['stars'] == 3 and info['earned'] == 185
        page.screenshot(path='build/logs/web-stage-complete-mobile.png')
        bounds = page.locator('canvas').bounding_box()
        page.touchscreen.tap(bounds['x'] + info['replay'][0] * bounds['width'], bounds['y'] + info['replay'][1] * bounds['height'])
        for _ in range(120):
            if sum('DEADLIGHT_READY district=1 version=0.11.0' in line for line in messages) >= 2:
                break
            page.wait_for_timeout(100)
        assert sum('DEADLIGHT_READY district=1 version=0.11.0' in line for line in messages) >= 2, messages
        assert sum('DEADLIGHT_FINALE ' in line for line in messages) == 1, 'Replay reran the fixture instead of the game'
        errors += [line for line in messages if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')]
        Path('build/logs/web-finale-console.json').write_text(json.dumps(messages, indent=2))
        assert not errors, errors
        print('WEB_FINALE_OK actual mission triggers, reward save, WebGL results and touch replay')
        browser.close()
finally:
    server.shutdown()
