"""Map Godot's landscape content through the canvas's letterboxed presentation."""
def game_bounds(page):
    canvas = page.locator('canvas').bounding_box()
    width = min(canvas['width'], canvas['height'] * 16 / 9)
    height = width * 9 / 16
    return {'x': canvas['x'] + (canvas['width'] - width) / 2,
            'y': canvas['y'] + (canvas['height'] - height) / 2,
            'width': width, 'height': height}


def point(bounds, normalized):
    return {'x': bounds['x'] + normalized[0] * bounds['width'],
            'y': bounds['y'] + normalized[1] * bounds['height']}
