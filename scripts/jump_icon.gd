extends Control
# The button texture includes the jumping silhouette; retain airborne feedback.
var airborne := false
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _draw() -> void:
    modulate.a = 0.72 if airborne else 1.0
