extends Control
const Assets = preload("res://scripts/hud_assets.gd")
var weapon_index := 1
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
    draw_texture_rect(Assets.texture("gun"), Rect2(Vector2.ZERO, size), false)
