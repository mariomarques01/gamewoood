"""Map logical landscape controls onto the full-screen, possibly rotated canvas."""
def game_bounds(page):
    canvas = page.locator('canvas').bounding_box()
    canvas['rotated'] = page.locator('canvas').get_attribute('data-landscape-rotation') == '90'
    return canvas


def point(bounds, normalized):
    if bounds.get('rotated'):
        return {'x': bounds['x'] + (1 - normalized[1]) * bounds['width'],
                'y': bounds['y'] + normalized[0] * bounds['height']}
    return {'x': bounds['x'] + normalized[0] * bounds['width'],
            'y': bounds['y'] + normalized[1] * bounds['height']}
