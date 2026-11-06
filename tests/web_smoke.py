"""Run the actual Web export; fail on browser or Godot errors and missing startup."""
import argparse
import functools
import http.server
import json
import io
from PIL import Image, ImageChops, ImageStat
import os
import re
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright
from web_geometry import game_bounds, point

AUDIO_PROBE_JS = r"""
(() => {
  window.__deadlightAudio = [];
  const Base = window.AudioContext || window.webkitAudioContext;
  if (!Base) return;
  const Wrapped = new Proxy(Base, {construct(target, args) {
    const ctx = Reflect.construct(target, args);
    window.__deadlightAudio.push(ctx);
    return ctx;
  }});
  window.AudioContext = Wrapped;
  if (window.webkitAudioContext) window.webkitAudioContext = Wrapped;
  const connect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function(target, ...args) {
    if (target instanceof AudioDestinationNode) {
      const ctx = this.context;
      if (!ctx.__deadlightAnalyser) {
        ctx.__deadlightAnalyser = ctx.createAnalyser();
        ctx.__deadlightAnalyser.fftSize = 2048;
        connect.call(ctx.__deadlightAnalyser, target);
      }
      return connect.call(this, ctx.__deadlightAnalyser, ...args);
    }
    return connect.call(this, target, ...args);
  };
})();
"""
ENERGY_JS = r"""async () => {
  let peak = 0;
  for (let i = 0; i < 12; i++) {
    for (const ctx of (window.__deadlightAudio || [])) {
      if (!ctx.__deadlightAnalyser) continue;
      const values = new Float32Array(2048);
      ctx.__deadlightAnalyser.getFloatTimeDomainData(values);
      let sum = 0;
      for (const value of values) sum += value * value;
      peak = Math.max(peak, Math.sqrt(sum / values.length));
    }
    await new Promise(resolve => setTimeout(resolve, 25));
  }
  return peak;
}"""

parser = argparse.ArgumentParser()
parser.add_argument('--directory')
parser.add_argument('--url')
parser.add_argument('--menu-only', action='store_true')
parser.add_argument('--profiles', nargs='+', choices=['impact','desktop','mobile','portrait'], default=['impact','desktop','mobile','portrait'])
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
        for name, size, mobile in [('impact', {'width': 1280, 'height': 720}, False),
                                   ('desktop', {'width': 1280, 'height': 720}, False),
                                   ('mobile', {'width': 844, 'height': 390}, True),
                                   ('portrait', {'width': 390, 'height': 844}, True)]:
            if name not in args.profiles:
                continue
            context = browser.new_context(viewport=size, is_mobile=mobile, has_touch=mobile)
            context.add_init_script(AUDIO_PROBE_JS)
            if name == 'portrait':
                # Exercise the real fallback required on browsers without fullscreen
                # or orientation-lock APIs, rather than relying on an OS rotation.
                context.add_init_script("Element.prototype.requestFullscreen = undefined; if (screen.orientation) screen.orientation.lock = () => Promise.reject(new Error('Unsupported orientation lock'));")
            page = context.new_page()
            messages, errors = [], []
            page.on('console', lambda msg: messages.append(msg.text))
            page.on('pageerror', lambda error: errors.append(str(error)))
            def expect_log(token, attempts=60):
                for attempt in range(attempts):
                    if any(token in line for line in messages):
                        return
                    page.wait_for_timeout(100)
                raise AssertionError(messages)

            response = page.goto(url, wait_until='networkidle', timeout=120000)
            assert response.ok, response.status
            # The supplied artwork is the actual first screen, with no hidden combat.
            expect_log('DEADLIGHT_MENU_READY version=0.15.0', attempts=600)
            assert not any('DEADLIGHT_READY district=1' in line for line in messages)
            bounds = game_bounds(page)
            screenshot = page.screenshot(timeout=60000)
            Path(f'build/logs/{name}-start-menu.png').write_bytes(screenshot)
            image = Image.open(io.BytesIO(screenshot)).convert('RGB')
            crop = image.crop((bounds['x'], bounds['y'], bounds['x'] + bounds['width'], bounds['y'] + bounds['height']))
            if bounds['rotated']:
                crop = crop.transpose(Image.Transpose.ROTATE_90)
            assert abs(bounds['width'] - page.viewport_size['width']) < 2 and abs(bounds['height'] - page.viewport_size['height']) < 2, 'Game has borders'
            assert page.locator('canvas').evaluate('(c) => c.width > c.height'), 'Render surface is portrait'
            assert bounds['rotated'] == (page.viewport_size['height'] > page.viewport_size['width']), 'Portrait browser was not rotated'
            badge_area = crop.crop((crop.width * .29, crop.height * .815, crop.width * .33, crop.height * .89))
            badge_pixels = list(badge_area.getdata())
            assert sum(r > 160 and r > g * 1.8 and r > b * 1.8 for r,g,b in badge_pixels) / len(badge_pixels) < .1, 'Arsenal notification badge is still visible'
            reference = Image.open('assets/menu/start-screen.png').convert('RGB').resize((160,90))
            difference = ImageChops.difference(crop.resize((160,90)), reference)
            assert sum(ImageStat.Stat(difference).mean) / 3 < 12, 'Startup artwork was cropped, distorted or replaced'
            def tap_menu(normalized):
                target = point(game_bounds(page), normalized)
                if mobile:
                    page.touchscreen.tap(**target)
                else:
                    page.mouse.click(**target)
            tap_menu((0.25, 650 / 720))
            expect_log('DEADLIGHT_MENU_PROGRESSION arsenal')
            expect_log('DEADLIGHT_PROGRESSION_CONTROLS ')
            panel_controls = json.loads(next(line.split('DEADLIGHT_PROGRESSION_CONTROLS ',1)[1] for line in reversed(messages) if 'DEADLIGHT_PROGRESSION_CONTROLS ' in line))
            tap_menu(panel_controls['back'])
            assert not any('DEADLIGHT_MENU_PLAY' in line for line in messages)
            tap_menu((960 / 1280, 650 / 720))
            expect_log('DEADLIGHT_MENU_AUDIO_CONTROLS ')
            menu_controls = json.loads(next(line.split('DEADLIGHT_MENU_AUDIO_CONTROLS ',1)[1] for line in reversed(messages) if 'DEADLIGHT_MENU_AUDIO_CONTROLS ' in line))
            for key, value in [('music', .31), ('effects', .59)]:
                rect = menu_controls[key]
                tap_menu((rect[0] + rect[2] * value, rect[1] + rect[3] * .5))
            tap_menu(menu_controls['back'])
            expect_log('DEADLIGHT_MENU_SETTINGS_SAVED ')
            saved = next(line for line in reversed(messages) if 'DEADLIGHT_MENU_SETTINGS_SAVED ' in line)
            levels = re.search(r'music=([0-9.]+) effects=([0-9.]+)', saved)
            assert levels and abs(float(levels[1]) - .31) < .03 and abs(float(levels[2]) - .59) < .03, saved
            assert not any('DEADLIGHT_READY district=1' in line for line in messages)
            tap_menu((.5, 525 / 720))
            expect_log('DEADLIGHT_READY district=1 version=0.15.0', attempts=600)
            expect_log('DEADLIGHT_ORIENTATION landscape')
            assert not any('DEADLIGHT_ORIENTATION portrait' in line for line in messages)
            if name == 'portrait':
                assert not page.evaluate('!!document.fullscreenElement'), 'Fallback depends on fullscreen'
                for rotated_size in [{'width': 844, 'height': 390}, {'width': 390, 'height': 844}]:
                    page.set_viewport_size(rotated_size)
                    page.wait_for_timeout(300)
                    assert page.locator('canvas').evaluate('(c) => c.width > c.height'), 'Rotation returned to portrait rendering'
                    resized = game_bounds(page)
                    assert abs(resized['width'] - rotated_size['width']) < 2 and abs(resized['height'] - rotated_size['height']) < 2, 'Rotation introduced borders'
                page.screenshot(path='build/logs/portrait-landscape-game.png')
            page.wait_for_timeout(500)
            bounds = game_bounds(page)
            print(f'WEB_START_MENU_OK {name} artwork, settings, arsenal and landscape play', flush=True)
            if args.menu_only:
                context.close()
                continue
            expect_log('DEADLIGHT_HUD_CONTROLS ')
            hud_positions = json.loads(next(line.split('DEADLIGHT_HUD_CONTROLS ', 1)[1] for line in reversed(messages) if 'DEADLIGHT_HUD_CONTROLS ' in line))
            def screen_control(key):
                return point(bounds, hud_positions[key])
            if name == 'impact':
                # Start grounded and stationary: a projection captured before a
                # jump/moving follow-camera settles is not a stable aiming target.
                page.keyboard.press('Escape', delay=120)
                expect_log('DEADLIGHT_COMBAT_TARGET ')
                target = json.loads(next(line.split('DEADLIGHT_COMBAT_TARGET ', 1)[1] for line in reversed(messages) if 'DEADLIGHT_COMBAT_TARGET ' in line))
                page.keyboard.press('Escape', delay=120)
                expect_log('DEADLIGHT_PAUSE false')
                page.mouse.move(**point(bounds, target))
                page.mouse.down()
                # Software WebGL may advance game time slowly; native tests verify
                # the 0.65s fuse, this gate verifies actual browser execution.
                expect_log('DEADLIGHT_CANISTER_ARMED', attempts=200)
                page.mouse.up()
                expect_log('DEADLIGHT_CANISTER_EXPLODED', attempts=200)
                page.screenshot(path='build/logs/web-energy-combat.png')
                errors += [line for line in messages if 'SCRIPT ERROR:' in line or line.startswith('ERROR:')]
                Path('build/logs/impact-console.json').write_text(json.dumps(messages, indent=2))
                assert not errors, errors
                print(f'WEB_IMPACT_OK mouse projectiles fuse explosion {url}')
                context.close()
                continue
            if mobile:
                session = context.new_cdp_session(page)
                x, y, width, height = (bounds[key] for key in ('x', 'y', 'width', 'height'))
                points = [{'id': 0, **screen_control('move')}, {'id': 1, **screen_control('aim')}]
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points})
                points[0].update(point(bounds, (hud_positions['move'][0] + .05, hud_positions['move'][1])))
                points[1].update(point(bounds, (hud_positions['aim'][0], hud_positions['aim'][1] - .1)))
                session.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': points})
                page.wait_for_timeout(300)
                # Input coordinates use the landscape content, including in portrait windows.
                scale = height / 540 if width > height else width / 540
                jump_point = {'id': 2, **screen_control('jump')}
                session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points + [jump_point]})
                page.wait_for_timeout(250)
                expect_log('DEADLIGHT_JUMP')
                session.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
                # CDP touchEnd releases the full gesture. Re-acquire both sticks
                # for each third-finger selection instead of faking partial ends.
                base_points = [{'id': 0, **screen_control('move')}, {'id': 1, **screen_control('aim')}]
                for token in ['pistol', 'machine']:
                    session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': base_points})
                    session.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': points})
                    selector = {'id': 3, **screen_control('swap')}
                    session.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': points + [selector]})
                    expect_log('DEADLIGHT_WEAPON ' + token)
                    session.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
                assert any('DEADLIGHT_CONTROLS simultaneous' in line for line in messages), messages
            else:
                page.keyboard.down('d')
                expect_log('DEADLIGHT_MOVE')
                # Release once movement executes; slow software rendering must not
                # keep walking across the entire arena while mouse calls settle.
                page.keyboard.up('d')
                page.keyboard.press('Space')
                page.keyboard.press('1')
                expect_log('DEADLIGHT_WEAPON pistol')
                page.mouse.move(**point(bounds, (.75, .6)))
                page.mouse.down()
                expect_log('DEADLIGHT_FIRE')
                page.wait_for_timeout(300)
                page.mouse.up()
                page.keyboard.press('2')
                expect_log('DEADLIGHT_WEAPON machine')
            expect_log('DEADLIGHT_AUDIO_UNLOCKED')
            expect_log('DEADLIGHT_MUSIC_STARTED')
            assert any('DEADLIGHT_JUMP' in line for line in messages), messages
            assert any('DEADLIGHT_MOVE' in line for line in messages), messages
            expect_log('DEADLIGHT_FIRE')
            if mobile:
                page.touchscreen.tap(**screen_control('pause'))
            else:
                page.keyboard.press('Escape', delay=120)
            page.wait_for_timeout(200)
            expect_log('DEADLIGHT_PAUSE true')
            expect_log('DEADLIGHT_AUDIO_CONTROLS ')
            # Pause before asynchronous Web Audio probing: software rendering can
            # stretch wall-clock waits enough for an unattended run to end.
            # The context resumes asynchronously; allow the worklet and music fade
            # to produce real samples after the first gesture, including rotation.
            energy = 0
            for _ in range(16):
                energy = page.evaluate(ENERGY_JS)
                if energy > 1e-6:
                    break
            assert energy > 1e-6, ('Audio graph was silent after gesture', energy, page.evaluate('window.__deadlightAudio.map(ctx => ({state: ctx.state, rate: ctx.sampleRate}))'), messages)
            page.screenshot(path=f'build/logs/{name}-audio-menu.png')
            controls = json.loads(next(line.split('DEADLIGHT_AUDIO_CONTROLS ', 1)[1] for line in reversed(messages) if 'DEADLIGHT_AUDIO_CONTROLS ' in line))
            def tap_audio_control(normalized):
                target = point(bounds, normalized)
                px, py = target['x'], target['y']
                if mobile:
                    page.touchscreen.tap(px, py)
                else:
                    page.mouse.click(px, py)
            tap_audio_control(controls['mute'])
            expect_log('DEADLIGHT_AUDIO_MUTED true')
            page.wait_for_timeout(300)
            silent = 1
            for _ in range(16):
                silent = page.evaluate(ENERGY_JS)
                if silent < 1e-6:
                    break
            assert silent < 1e-6, ('Mute left audible audio', silent, messages)
            tap_audio_control(controls['mute'])
            expect_log('DEADLIGHT_AUDIO_MUTED false')
            music_rect = controls['music']
            tap_audio_control([music_rect[0] + music_rect[2] * .25, music_rect[1] + music_rect[3] * .5])
            effects_rect = controls['effects']
            tap_audio_control([effects_rect[0] + effects_rect[2] * .65, effects_rect[1] + effects_rect[3] * .5])
            Path(f'build/logs/{name}-audio.json').write_text(json.dumps({'output_rms': energy, 'muted_rms': silent, 'controls': controls}, indent=2))
            print(f'WEB_AUDIO_OK {name} signal={energy:.7f} mute={silent:.7f}')
            page.screenshot(path=f'build/logs/{name}-paused.png')
            if mobile:
                page.touchscreen.tap(**screen_control('pause'))
            else:
                page.keyboard.press('Escape', delay=120)
            page.wait_for_timeout(200)
            expect_log('DEADLIGHT_PAUSE false')
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
