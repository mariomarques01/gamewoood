"""Read the rendered mission guide after waves and exercise the real map by touch."""
import argparse
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
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
Path('build/logs').mkdir(parents=True, exist_ok=True)
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=os.environ.get('CHROMIUM_BIN'), args=['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        for name, size in [('mobile', {'width': 844, 'height': 390}), ('portrait', {'width': 390, 'height': 844})]:
            context = browser.new_context(viewport=size, is_mobile=True, has_touch=True)
            page = context.new_page()
            messages, errors = [], []
            page.on('console', lambda message: messages.append(message.text))
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.goto(f'http://127.0.0.1:{server.server_port}/', wait_until='networkidle', timeout=120000)
            def wait_case(index):
                for _ in range(900):
                    for line in reversed(messages):
                        if 'DEADLIGHT_GUIDANCE_CASE ' in line:
                            data = json.loads(line.split('DEADLIGHT_GUIDANCE_CASE ', 1)[1])
                            if data['case'] == index:
                                return data
                    page.wait_for_timeout(100)
                raise AssertionError(messages[-25:])
            for _ in range(900):
                if any('DEADLIGHT_RENDER_CASE 0' in line for line in messages):
                    break
                page.wait_for_timeout(100)
            assert any('DEADLIGHT_RENDER_CASE 0' in line for line in messages), messages
            previous_progress = 0
            for index in range(6):
                page.keyboard.press('g')
                data = wait_case(index)
                if index == 0:
                    assert data['visible'] and 'LIBERE O ARSENAL' in data['heading']
                    assert 'FALTAM 3 MISSÕES' in data['wave'] and '3s' in data['instruction'] and 'ÁREA VERDE' in data['status']
                    rect = data['rect']
                    assert min(rect) >= 0 and rect[0] + rect[2] <= 1 and rect[1] + rect[3] <= 1, data
                    page.screenshot(path=f'build/logs/web-guide-{name}-after-waves.png')
                    page.touchscreen.tap(**point(game_bounds(page), data['map']))
                elif index == 1:
                    assert data['map_open'] and not data['visible']
                    assert 'ATUAL' in data['tasks'][0] and 'COMUNICAÇÃO' in data['tasks'][2]
                    rect = data['map_rect']
                    assert min(rect) >= 0 and rect[0] + rect[2] <= 1 and rect[1] + rect[3] <= 1, data
                    page.screenshot(path=f'build/logs/web-guide-{name}-map.png')
                    page.touchscreen.tap(**point(game_bounds(page), data['close']))
                elif index == 2:
                    assert data['visible'] and 'CAPTURANDO' in data['status'] and data['progress'] > 0
                    previous_progress = data['progress']
                elif index == 3:
                    assert 'BLOQUEADA' in data['status'] and 'Elimine os inimigos' in data['instruction']
                    assert data['progress'] == previous_progress, data
                    page.screenshot(path=f'build/logs/web-guide-{name}-contested.png')
                elif index == 4:
                    assert 'ATIVE O HELIPONTO' in data['heading'] and data['checklist'][0].startswith('OK')
                    assert 'FALTAM 2 MISSÕES' in data['wave']
                else:
                    assert data['won'] and not data['visible'], data
            errors += [line for line in messages if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')]
            Path(f'build/logs/web-guide-{name}-console.json').write_text(json.dumps(messages, indent=2))
            assert not errors, errors
            print(f'WEB_MISSION_GUIDANCE_OK {name} after-waves map touch capture contested next victory', flush=True)
            context.close()
        browser.close()
finally:
    server.shutdown()
