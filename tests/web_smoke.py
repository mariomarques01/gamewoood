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
                                   ('mobile', {'width': 844, 'height': 390}, True),
                                   ('portrait', {'width': 390, 'height': 844}, True)]:
            context = browser.new_context(viewport=size, is_mobile=mobile, has_touch=mobile)
            page = context.new_page()
            messages, errors = [], []
            page.on('console', lambda msg: messages.append(msg.text))
            page.on('pageerror', lambda error: errors.append(str(error)))
            response = page.goto(url, wait_until='networkidle', timeout=120000)
            assert response.ok, response.status
            # A printed sentinel originates in the executed GDScript, not the HTML shell.
            for _ in range(120):
                if any('DEADLIGHT_READY district=1 version=0.4.0' in line for line in messages):
                    break
                page.wait_for_timeout(500)
            assert any('DEADLIGHT_READY district=1 version=0.4.0' in line for line in messages), messages
            page.wait_for_timeout(1000)
            bounds = page.locator('canvas').bounding_box()
            if mobile:
                session = context.new_cdp_session(page)
                x, y, width, height = (bounds[key] for key in ('x', 'y', 'width', 'height'))
                points = [{'id': 0, 'x': x + 105, 'y': y + height - 100},
                          {'id': 1, 'x': x + width - 105, 'y': y + height - 100}]
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points})
                points[0]['x'] += 30
                points[1]['y'] -= 35
                session.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': points})
                page.wait_for_timeout(300)
                # HUD uses 540 logical units across in portrait, 540 vertically in landscape.
                scale = height / 540 if width > height else width / 540
                jump_point = {'id': 2, 'x': x + width - 74 * scale, 'y': y + height - 226 * scale}
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points + [jump_point]})
                page.wait_for_timeout(250)
                assert any('DEADLIGHT_JUMP' in line for line in messages), messages
                session.send('Input.dispatchTouchEvent', {'type': 'touchEnd' , 'touchPoints': []})
                assert any('DEADLIGHT_CONTROLS simultaneous' in line for line in messages), messages
            else:
                page.keyboard.down('d')
                page.keyboard.press('Space')
                page.mouse.move(bounds['x'] + bounds['width'] * 0.75, bounds['y'] + bounds['height'] * 0.6)
                page.mouse.down()
                page.wait_for_timeout(700)
                page.keyboard.up('d')
                page.mouse.up()
            assert any('DEADLIGHT_JUMP' in line for line in messages), messages
            assert any('DEADLIGHT_MOVE' in line for line in messages), messages
            assert any('DEADLIGHT_FIRE' in line for line in messages), messages
            if mobile:
                page.touchscreen.tap(bounds['x'] + bounds['width'] - 48 * scale, bounds['y'] + 50 * scale)
            else:
                page.keyboard.press('Escape')
            page.wait_for_timeout(200)
            assert any('DEADLIGHT_PAUSE true' in line for line in messages), messages
            page.screenshot(path=f'build/logs/{name}-paused.png')
            if mobile:
                page.touchscreen.tap(bounds['x'] + bounds['width'] - 48 * scale, bounds['y'] + 50 * scale)
            else:
                page.keyboard.press('Escape')
            page.wait_for_timeout(200)
            assert any('DEADLIGHT_PAUSE false' in line for line in messages), messages
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
