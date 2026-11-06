"""Render the real completion UI and replay in WebGL using the isolated QA export."""
import argparse
from collections import Counter
import io
from PIL import Image
import functools
import http.server
import json
import os
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright
from web_geometry import game_bounds, point

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
        messages, errors, all_messages = [], [], []
        page.on('console', lambda message: (messages.append(message.text), all_messages.append(message.text)))
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
        screenshot = page.screenshot(path='build/logs/web-stage-complete-mobile.png')
        frame = Image.open(io.BytesIO(screenshot)).convert('RGB')
        scene = frame.crop((frame.width * .05, frame.height * .35, frame.width * .5, frame.height * .95)).resize((64, 32))
        assert Counter(scene.getdata()).most_common(1)[0][1] / (64 * 32) < .9, 'Victory camera is occluded'

        bounds = game_bounds(page)
        page.touchscreen.tap(**point(bounds, info['replay']))
        for _ in range(120):
            if sum('DEADLIGHT_READY district=1 version=0.15.1' in line for line in messages) >= 2:
                break
            page.wait_for_timeout(100)
        assert sum('DEADLIGHT_READY district=1 version=0.15.1' in line for line in messages) >= 2, messages
        assert sum('DEADLIGHT_FINALE ' in line for line in messages) == 1, 'Replay reran the fixture instead of the game'
        # Return from a real earned reward to the menu, buy and persist a loadout.
        def wait_log(prefix):
            for _ in range(600):
                matches = [line.split(prefix,1)[1] for line in messages if prefix in line]
                if matches:
                    return matches[-1]
                page.wait_for_timeout(100)
            raise AssertionError(messages[-20:])
        def tap(normalized):
            page.touchscreen.tap(**point(game_bounds(page), normalized))
        fixture_url = page.url
        messages.clear()
        page.goto(fixture_url, wait_until='networkidle', timeout=120000)
        info = json.loads(wait_log('DEADLIGHT_WEB_FINALE_FIXTURE '))
        tap(info['menu'])
        wait_log('DEADLIGHT_MENU_READY version=0.15.1')
        tap((320 / 1280, 650 / 720))
        controls = json.loads(wait_log('DEADLIGHT_PROGRESSION_CONTROLS '))
        rect = controls['panel']
        assert rect[0] >= 0 and rect[1] >= 0 and rect[0] + rect[2] <= 1 and rect[1] + rect[3] <= 1, 'Arsenal is cropped after gameplay'
        tap(controls['pistol'])
        page.wait_for_timeout(250)
        tap(controls['damage'])
        tap(controls['equip'])
        page.wait_for_timeout(500)
        page.screenshot(path='build/logs/web-arsenal-purchased-mobile.png')
        tap(controls['back'])
        messages.clear()
        tap((.5, 525 / 720))
        loadout = json.loads(wait_log('DEADLIGHT_LOADOUT '))
        assert loadout['weapon'] == 0 and loadout['damage'][0] == 1, loadout
        # A new page/engine must read the same purchased loadout from IndexedDB.
        page.wait_for_timeout(1000)
        messages.clear()
        page.reload(wait_until='networkidle', timeout=120000)
        loadout = json.loads(wait_log('DEADLIGHT_LOADOUT '))
        assert loadout['weapon'] == 0 and loadout['damage'][0] == 1, loadout
        errors += [line for line in all_messages if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')]
        Path('build/logs/web-finale-console.json').write_text(json.dumps(all_messages, indent=2))
        assert not errors, errors
        print('WEB_FINALE_OK actual mission triggers, reward save, WebGL results, touch replay, menu purchase and persistent loadout')
        browser.close()
finally:
    server.shutdown()
