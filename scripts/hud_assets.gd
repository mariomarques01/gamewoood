extends RefCounted
# Shared raster artwork; AtlasTexture preserves transparency and pixel detail.
static var atlas: Texture2D
static var regions: Dictionary = {}
static var textures: Dictionary = {}

static func texture(key: String) -> Texture2D:
    if textures.has(key):
        return textures[key]
    if atlas == null:
        atlas = load("res://assets/hud/reference-atlas.png")
        regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hud/atlas-regions.json"))
    var rect: Array = regions[key]
    var result := AtlasTexture.new()
    result.atlas = atlas
    result.region = Rect2(rect[0], rect[1], rect[2], rect[3])
    textures[key] = result
    return result

static func style(key: String, margin: float = 0) -> StyleBoxTexture:
    var style := StyleBoxTexture.new()
    style.texture = texture(key)
    style.set_texture_margin_all(margin)
    return style
