extends CanvasLayer
signal pause_requested
signal restart_requested
const MobileControls = preload("res://scripts/mobile_controls.gd")
const HUDArt = preload("res://scripts/hud_art.gd")
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
var art: Control
var captain: Label
var life: Label
var ammo_text: Label
var kills_text: Label
var mission_title: Label
var pause_button: Button
var restart_button: Button
var jump_button: Button
var jump_hint: Label

func _style(color: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style

func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
    var label := Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    root.add_child(label)
    return label

func _button(text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.add_theme_font_size_override("font_size", 24)
    button.add_theme_stylebox_override("normal", _style(Color(0.07, 0.12, 0.18, 0.95), Color(0.45, 0.61, 0.7)))
    button.add_theme_stylebox_override("hover", _style(Color(0.12, 0.23, 0.3), Color(0.4, 0.9, 1)))
    button.add_theme_stylebox_override("pressed", _style(Color(0.4, 0.25, 0.05), Color(1, 0.7, 0.15)))
    button.focus_mode = Control.FOCUS_NONE
    root.add_child(button)
    return button

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls = MobileControls.new()
    root.add_child(controls)
    art = HUDArt.new()
    root.add_child(art)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    captain = _label("CAPITAO TRANCO", 21)
    life = _label("100 / 100", 16, Color(0.5, 0.9, 0.75))
    ammo_text = _label("24 / 24", 26, Color(1, 0.8, 0.3))
    kills_text = _label("ALIENS  0", 18)
    mission_title = _label("OPERACAO BASE SEGURA", 15, Color(1, 0.72, 0.22))
    objective = _label("LIBERE O ARSENAL", 20)
    objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    progress = ProgressBar.new()
    progress.max_value = 1.0
    progress.show_percentage = false
    for entry in [["background", Color(0.12, 0.19, 0.23)], ["fill", Color(1, 0.65, 0.1)]]:
        var bar_style := StyleBoxFlat.new()
        bar_style.bg_color = entry[1]
        bar_style.set_corner_radius_all(3)
        progress.add_theme_stylebox_override(entry[0], bar_style)
    root.add_child(progress)
    pause_button = _button("II")
    pause_button.pressed.connect(func(): pause_requested.emit())
    jump_button = _button("PULAR")
    jump_button.add_theme_font_size_override("font_size", 20)
    jump_button.add_theme_stylebox_override("normal", _style(Color(0.1, 0.24, 0.3, 0.94), Color(0.1, 0.85, 1)))
    jump_button.pressed.connect(_request_jump)
    jump_hint = _label("ESPACO: PULAR", 15, Color(0.7, 0.84, 0.9))
    controls.jump_button = jump_button
    controls.jump_requested.connect(_request_jump)
    damage_flash = ColorRect.new()
    root.add_child(damage_flash)
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_flash.color = Color(1, 0.05, 0.02, 0)
    overlay = PanelContainer.new()
    root.add_child(overlay)
    overlay.add_theme_stylebox_override("panel", _style(Color(0.03, 0.06, 0.1, 0.98), Color(1, 0.65, 0.1)))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 18)
    overlay.add_child(box)
    outcome = Label.new()
    outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    outcome.add_theme_font_size_override("font_size", 26)
    outcome.add_theme_color_override("font_color", Color(1, 0.75, 0.2))
    box.add_child(outcome)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 16)
    box.add_child(status)
    resume = _button("CONTINUAR")
    resume.reparent(box)
    resume.custom_minimum_size.y = 64
    resume.pressed.connect(func(): pause_requested.emit())
    restart_button = _button("REINICIAR BASE")
    restart_button.reparent(box)
    restart_button.custom_minimum_size.y = 64
    restart_button.pressed.connect(func(): restart_requested.emit())
    overlay.hide()
    navigation = _label("", 21, Color(0.55, 1, 0.65))
    navigation.add_theme_color_override("font_shadow_color", Color.BLACK)
    navigation.add_theme_constant_override("shadow_outline_size", 5)
    get_viewport().size_changed.connect(_layout)
    _layout()

func _layout() -> void:
    var viewport := get_viewport()
    var pixels := viewport.get_window().size
    var desired := Vector2i(540, 960) if pixels.x < pixels.y else Vector2i(960, 540)
    if viewport.content_scale_size != desired:
        viewport.content_scale_size = desired
    var area := viewport.get_visible_rect().size
    var portrait := area.x < area.y
    var health_width := minf(330, area.x - 104)
    art.health_rect = Rect2(16, 18, health_width, 94)
    art.ammo_rect = Rect2(16, 124, 155, 80) if portrait else Rect2(area.x - 238, 18, 144, 94)
    var mission_y := 218.0 if portrait else 18.0
    var mission_x := 16.0 if portrait else 364.0
    var mission_width := area.x - 32 if portrait else area.x - 620
    art.mission_rect = Rect2(mission_x, mission_y, mission_width, 100)
    captain.position = art.health_rect.position + Vector2(89, 13)
    life.position = art.health_rect.position + Vector2(89, 67)
    ammo_text.position = art.ammo_rect.position + Vector2(62, 7)
    kills_text.position = art.ammo_rect.position + Vector2(14, 48)
    mission_title.position = art.mission_rect.position + Vector2(14, 10)
    objective.position = art.mission_rect.position + Vector2(14, 34)
    objective.size = Vector2(mission_width - 28, 50)
    objective.add_theme_font_size_override("font_size", 18 if mission_width < 380 else 21)
    progress.position = art.mission_rect.position + Vector2(14, 84)
    progress.size = Vector2(mission_width - 28, 7)
    pause_button.position = Vector2(area.x - 78, 18)
    pause_button.size = Vector2(60, 64)
    jump_button.position = Vector2(area.x - 126, area.y - 264)
    jump_button.size = Vector2(104, 76)
    jump_hint.visible = not portrait
    jump_hint.position = Vector2(area.x - 164, area.y - 294)
    overlay.position = area * 0.5 - Vector2(minf(460, area.x - 32), 340) * 0.5
    overlay.size = Vector2(minf(460, area.x - 32), 340)
    art.queue_redraw()
    controls.queue_redraw()

func _request_jump() -> void:
    if is_instance_valid(player) and not overlay.visible and not get_tree().paused:
        player.request_jump()

func _process(delta: float) -> void:
    navigation_timer -= delta
    if navigation_timer > 0 or not is_instance_valid(player) or not is_instance_valid(mission):
        return
    navigation_timer = 0.1
    jump_button.text = "PULAR" if player.is_on_floor() else "NO AR"
    navigation.visible = mission.active and not overlay.visible
    if not navigation.visible:
        return
    var target: Vector3 = mission.POSITIONS[mission.current] + Vector3.UP * 2.5
    var camera := get_viewport().get_camera_3d()
    var screen := camera.unproject_position(target)
    var area := get_viewport().get_visible_rect().size
    if camera.is_position_behind(target):
        screen = area * 0.5 - (screen - area * 0.5)
    navigation.position = screen.clamp(Vector2(24, art.mission_rect.end.y + 16), area - Vector2(120, 300))
    navigation.text = "OBJETIVO  %dm" % int(player.global_position.distance_to(target))

func update_status(hp: float, ammo: int, reload_active: bool, kills: int, current_mission: Node) -> void:
    status.text = "BAIRRO 1 v0.4.0  |  BASE DO CAPITAO"
    life.text = "%d / 100" % int(ceil(hp))
    art.health_ratio = hp / 100.0
    art.queue_redraw()
    ammo_text.text = "REC..." if reload_active else "%02d / 24" % ammo
    kills_text.text = "ALIENS  %d" % kills
    mission_title.text = "OPERACAO BASE SEGURA  %d/3" % current_mission.current
    objective.text = current_mission.TITLES[mini(current_mission.current, 2)] if current_mission.current < 3 else "BASE PROTEGIDA!"
    if current_mission.contested:
        objective.text = "ELIMINE OS INVASORES!"
    progress.value = current_mission.progress

func show_overlay(text: String, paused: bool = false) -> void:
    outcome.text = text
    resume.visible = paused
    overlay.show()
    jump_button.hide()
    controls.enabled = false
    controls.reset()

func hide_overlay() -> void:
    overlay.hide()
    jump_button.show()
    controls.enabled = true

func flash() -> void:
    damage_flash.color.a = 0.25
    create_tween().tween_property(damage_flash, "color:a", 0.0, 0.25)
