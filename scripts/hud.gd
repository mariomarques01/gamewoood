extends CanvasLayer
signal pause_requested
signal restart_requested
const MobileControls = preload("res://scripts/mobile_controls.gd")
var controls: Control
var status: Label
var objective: Label
var progress: ProgressBar
var overlay: PanelContainer
var outcome: Label
var resume: Button
var root: Control
var damage_flash: ColorRect
var navigation: Label
var player: CharacterBody3D
var mission: Node
var navigation_timer := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls = MobileControls.new()
    root.add_child(controls)
    controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var header := MarginContainer.new()
    root.add_child(header)
    header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    header.add_theme_constant_override("margin_left", 72)
    header.add_theme_constant_override("margin_right", 72)
    header.add_theme_constant_override("margin_top", 16)
    var row := HBoxContainer.new()
    header.add_child(row)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(column)
    status = Label.new()
    status.add_theme_font_size_override("font_size", 20)
    column.add_child(status)
    objective = Label.new()
    objective.add_theme_font_size_override("font_size", 18)
    objective.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
    column.add_child(objective)
    progress = ProgressBar.new()
    progress.custom_minimum_size = Vector2(0, 8)
    progress.show_percentage = false
    progress.max_value = 1.0
    column.add_child(progress)
    var pause := Button.new()
    pause.text = "II"
    pause.custom_minimum_size = Vector2(60, 54)
    row.add_child(pause)
    pause.pressed.connect(func(): pause_requested.emit())
    damage_flash = ColorRect.new()
    root.add_child(damage_flash)
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_flash.color = Color(1, 0.05, 0.02, 0)
    overlay = PanelContainer.new()
    root.add_child(overlay)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    overlay.offset_left = -245
    overlay.offset_right = 245
    overlay.offset_top = -110
    overlay.offset_bottom = 110
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    overlay.add_child(box)
    outcome = Label.new()
    outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    outcome.add_theme_font_size_override("font_size", 24)
    box.add_child(outcome)
    resume = Button.new()
    resume.text = "CONTINUAR"
    resume.custom_minimum_size.y = 48
    resume.pressed.connect(func(): pause_requested.emit())
    box.add_child(resume)
    var restart := Button.new()
    restart.text = "REINICIAR BASE"
    restart.custom_minimum_size.y = 48
    restart.pressed.connect(func(): restart_requested.emit())
    box.add_child(restart)
    overlay.hide()
    navigation = Label.new()
    navigation.add_theme_font_size_override("font_size", 20)
    navigation.add_theme_color_override("font_color", Color(0.5, 1, 0.55))
    root.add_child(navigation)

func _process(delta: float) -> void:
    navigation_timer -= delta
    if navigation_timer > 0 or not is_instance_valid(player) or not is_instance_valid(mission):
        return
    navigation_timer = 0.1
    navigation.visible = mission.active and not overlay.visible
    if not navigation.visible:
        return
    var target: Vector3 = mission.POSITIONS[mission.current] + Vector3.UP * 2.5
    var camera := get_viewport().get_camera_3d()
    var screen := camera.unproject_position(target)
    var area := get_viewport().get_visible_rect().size
    if camera.is_position_behind(target):
        screen = area * 0.5 - (screen - area * 0.5)
    navigation.position = screen.clamp(Vector2(100, 125), area - Vector2(180, 200))
    navigation.text = "[ %dm ]" % int(player.global_position.distance_to(target))

func update_status(hp: float, ammo: int, reload_active: bool, kills: int, mission: Node) -> void:
    status.text = "BAIRRO 1 v0.3.0  |  BASE DO CAPITAO\nVIDA %d   |   %s   |   ALIENS %d" % [int(ceil(hp)), "RECARREGANDO" if reload_active else "MUNICAO %d/24" % ammo, kills]
    objective.text = "%d/3  %s%s" % [mission.current, mission.TITLES[mini(mission.current, 2)] if mission.current < 3 else "BASE PROTEGIDA!", " — ELIMINE OS INVASORES" if mission.contested else ""]
    progress.value = mission.progress

func show_overlay(text: String, paused: bool = false) -> void:
    outcome.text = text
    resume.visible = paused
    overlay.show()
    controls.enabled = false
    controls.reset()

func hide_overlay() -> void:
    overlay.hide()
    controls.enabled = true

func flash() -> void:
    damage_flash.color.a = 0.25
    create_tween().tween_property(damage_flash, "color:a", 0.0, 0.25)
