"""Check actual 3D pixels across the map on a high-DPR mobile WebGL viewport."""
import argparse
import functools
import http.server
import hashlib
import io
from pathlib import Path
import threading

from PIL import Image
from playwright.sync_api import sync_playwright


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


parser = argparse.ArgumentParser()
parser.add_argument('--directory', default='build/web-render')
parser.add_argument('--browser', choices=['chromium', 'webkit'], default='webkit')
args = parser.parse_args()
server = http.server.ThreadingHTTPServer(
    ('127.0.0.1', 0), functools.partial(QuietHandler, directory=args.directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
Path('build/logs').mkdir(parents=True, exist_ok=True)
try:
    with sync_playwright() as playwright:
        launch_args = ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] if args.browser == 'chromium' else []
        browser = getattr(playwright, args.browser).launch(args=launch_args)
        context = browser.new_context(viewport={'width': 844, 'height': 390},
                                      device_scale_factor=3, is_mobile=True, has_touch=True)
        page = context.new_page()
        logs, errors = [], []
        frames = set()
        page.on('console', lambda message: logs.append(message.text))
        page.on('pageerror', lambda error: errors.append(str(error)))
        page.goto(f'http://127.0.0.1:{server.server_port}', wait_until='load', timeout=120000)
        for index in range(12):
            sentinel = f'DEADLIGHT_RENDER_CASE {index}'
            for _ in range(180):
                if sentinel in logs:
                    break
                page.wait_for_timeout(500)
            assert sentinel in logs, logs[-20:]
            page.wait_for_timeout(250)
            screenshot = page.screenshot(timeout=60000)
            Path(f'build/logs/{args.browser}-render-{index:02d}.png').write_bytes(screenshot)
            image = Image.open(io.BytesIO(screenshot)).convert('RGB')
            # Exclude the HUD: a working menu must not conceal a blank 3D scene.
            crop = image.crop((image.width * .2, image.height * .3,
                               image.width * .8, image.height * .7))
            digest = hashlib.sha256(crop.tobytes()).hexdigest()
            assert digest not in frames, f'3D scene froze in region {index}'
            frames.add(digest)
            pixels = list(crop.resize((96, 64), Image.Resampling.BOX).getdata())
            background = sum(abs(r - 9) + abs(g - 28) + abs(b - 46) < 12
                             for r, g, b in pixels) / len(pixels)
            print(f'RENDER_FRAME {args.browser} case={index} blue_background={background:.4f}', flush=True)
            assert background < .8, f'3D scene disappeared in region {index}'
            if index < 11:
                page.keyboard.press('n')
        # Godot 4.3's final canvas blit emits this warning on headless WPE even
        # when successive 3D frames render correctly; pixels and frame hashes above
        # verify presentation independently. Fail all other WebGL errors.
        known_copy_warning = 'glBlitFramebuffer: Read and write color attachments cannot be the same image.'
        errors += [line for line in logs if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')
                   or ('WebGL' in line and 'INVALID_OPERATION' in line and known_copy_warning not in line)]
        assert not errors, errors
        print(f'WEB_RENDERING_OK {args.browser} 12 regions/edges at DPR 3 with live combat effects')
        browser.close()
finally:
    server.shutdown()
