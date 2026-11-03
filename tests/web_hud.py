"""Browser QA for the reference HUD and real three-finger controls."""
import argparse
import functools
import http.server
import json
import threading
from pathlib import Path
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--directory', default='build/web-hud')
parser.add_argument('--capture-only', action='store_true')
args = parser.parse_args()
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f'http://127.0.0.1:{server.server_port}/'
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        for width, height in [(1280, 590), (844, 390)]:
            context = browser.new_context(viewport={'width': width, 'height': height}, is_mobile=True, has_touch=True, device_scale_factor=1)
            page = context.new_page()
            messages, errors = [], []
            page.on('console', lambda m: messages.append(m.text))
            page.on('pageerror', lambda e: errors.append(str(e)))
            def expect(token):
                for _ in range(240):
                    if any(token in m for m in messages):
                        return
                    page.wait_for_timeout(250)
                raise AssertionError((token, messages))
            page.goto(url, wait_until='networkidle', timeout=120000)
            expect('DEADLIGHT_HUD_FIXTURE_READY')
            expect('DEADLIGHT_HUD_CONTROLS ')
            page.wait_for_timeout(350)
            layout = json.loads(next(m.split('DEADLIGHT_HUD_CONTROLS ', 1)[1] for m in reversed(messages) if 'DEADLIGHT_HUD_CONTROLS ' in m))
            bounds = page.locator('canvas').bounding_box()
            def point(key, identity):
                return {'id': identity, 'x': bounds['x'] + layout[key][0] * bounds['width'], 'y': bounds['y'] + layout[key][1] * bounds['height']}
            page.screenshot(path=f'build/logs/hud-browser-{width}x{height}.png')
            if args.capture_only:
                assert not errors, errors
                context.close()
                continue
            session = context.new_cdp_session(page)
            sticks = [point('move', 0), point('aim', 1)]
            session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': sticks})
            moved = [dict(sticks[0]), dict(sticks[1])]
            moved[0]['x'] += 35
            moved[1]['y'] -= 35
            session.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': moved})
            expect('DEADLIGHT_CONTROLS simultaneous')
            for token in ['pistol', 'machine']:
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': moved + [point('swap', 2)]})
                expect('DEADLIGHT_WEAPON ' + token)
                session.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': sticks})
                session.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': moved})
            session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': moved + [point('jump', 3)]})
            expect('DEADLIGHT_JUMP')
            session.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
            gear = point('pause', 0)
            page.touchscreen.tap(gear['x'], gear['y'])
            expect('DEADLIGHT_PAUSE true')
            page.screenshot(path=f'build/logs/hud-browser-settings-{width}.png')
            page.touchscreen.tap(gear['x'], gear['y'])
            expect('DEADLIGHT_PAUSE false')
            assert not errors, errors
            assert not [m for m in messages if 'SCRIPT ERROR:' in m or m.startswith('ERROR:')], messages
            Path(f'build/logs/hud-browser-{width}.json').write_text(json.dumps({'layout':layout,'messages':messages,'errors':errors}, indent=2))
            print(f'WEB_HUD_OK {width}x{height} real movement aim swap jump settings', flush=True)
            context.close()
        browser.close()
finally:
    server.shutdown()
