extends Node
# Native platforms permit a real sensor-landscape lock. Web uses the rotated
# canvas adapter, including inverse touch coordinates, before the first frame.
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if OS.has_feature("web"):
        return
    if OS.has_feature("android") or OS.has_feature("ios"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
    get_tree().root.size_changed.connect(_landscape_window)
    _landscape_window()

func _landscape_window() -> void:
    var window := get_tree().root
    if window.size.x < window.size.y:
        window.size = Vector2i(window.size.y, window.size.x)
