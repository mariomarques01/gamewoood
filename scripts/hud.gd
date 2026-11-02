extends CanvasLayer
@onready var audio: Node = get_node("/root/GameAudio")
signal pause_requested
signal restart_requested
signal orientation_changed(portrait: bool)
const MobileControls = preload("res://scripts/mobile_controls.gd")
const DisplayFont = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const TextFont = preload("res://assets/fonts/Nunito-ExtraBold.ttf")
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
var jump_icon: Control
var touch_buttons: Dictionary = {}
var music_slider: HSlider
var effects_slider: HSlider
var mute_button: Button
var audio_drag_id := -1
var audio_drag_slider: HSlider
var portrait_mode := false
var rotation_panel: Panel
var rotation_label: Label
var fullscreen_button: Button
var credit_text: Label
var kill_popup: Label
var kill_time := 0.0
var arcade: Node
var combo_meter: ProgressBar
var details: Label
var toast: Label
var toast_time := 0.0
var weapon_buttons: Array[Button] = []
var ammo_icon: Control
var reload_meter: ProgressBar
var results: Control
var xp_panel: Panel
var xp_meter: ProgressBar
var xp_text: Label
var frenzy_text: Label
var power_banner: Control

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
    label.add_theme_font_override("font", DisplayFont if font_size >= 20 else TextFont)
    label.add_theme_color_override("font_outline_color", Color(0.025, 0.045, 0.06, 0.95))
    label.add_theme_constant_override("outline_size", 3 if font_size >= 20 else 1)
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
    var interface_theme := Theme.new()
    interface_theme.default_font = TextFont
    interface_theme.default_font_size = 18
    root.theme = interface_theme
    controls = MobileControls.new()
    root.add_child(controls)
    art = HUDArt.new()
    root.add_child(art)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    captain = _label("CAPITÃO TRANCO", 21)
    life = _label("100 / 100", 16, Color(0.5, 0.9, 0.75))
    ammo_text = _label("24 / 24", 26, Color(1, 0.8, 0.3))
    kills_text = _label("ALIENS  0", 18)
    mission_title = _label("OPERAÇÃO BASE SEGURA", 15, Color(1, 0.72, 0.22))
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
    jump_button = _button("")
    jump_button.tooltip_text = "Saltar (Espaco)"
    jump_icon = preload("res://scripts/jump_icon.gd").new()
    jump_button.add_child(jump_icon)
    jump_button.add_theme_font_size_override("font_size", 20)
    jump_button.add_theme_stylebox_override("normal", _style(Color(0.1, 0.24, 0.3, 0.94), Color(0.1, 0.85, 1)))
    jump_button.pressed.connect(_request_jump)
    controls.jump_button = jump_button
    controls.jump_requested.connect(_request_jump)
    for index in range(2):
        var button := _button("")
        button.tooltip_text = "Pistola (1)" if index == 0 else "Metralhadora (2)"
        button.pressed.connect(_request_weapon.bind(index))
        var icon = preload("res://scripts/weapon_icon.gd").new()
        icon.weapon_index = index
        icon.position = Vector2(8, 5)
        icon.size = Vector2(56, 32)
        button.add_child(icon)
        var label := Label.new()
        label.text = "PISTOLA" if index == 0 else "METRALH."
        label.add_theme_font_size_override("font_size", 11)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.position = Vector2(0, 43)
        label.size = Vector2(72, 18)
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.add_child(label)
        weapon_buttons.append(button)
    controls.weapon_buttons = weapon_buttons
    ammo_icon = preload("res://scripts/weapon_icon.gd").new()
    root.add_child(ammo_icon)
    reload_meter = ProgressBar.new()
    reload_meter.max_value = 1
    reload_meter.show_percentage = false
    reload_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(reload_meter)
    damage_flash = ColorRect.new()
    root.add_child(damage_flash)
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    damage_flash.color = Color(1, 0.05, 0.02, 0)
    overlay = PanelContainer.new()
    root.add_child(overlay)
    overlay.add_theme_stylebox_override("panel", _style(Color(0.03, 0.06, 0.1, 0.98), Color(1, 0.65, 0.1)))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
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
    details = Label.new()
    details.add_theme_font_size_override("font_size", 18)
    details.add_theme_color_override("font_color", Color(0.75, 0.86, 0.91))
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(details)
    var audio_row := HBoxContainer.new()
    audio_row.add_theme_constant_override("separation", 8)
    box.add_child(audio_row)
    var music_label := Label.new()
    music_label.text = "MÚSICA"
    music_label.add_theme_font_size_override("font_size", 14)
    audio_row.add_child(music_label)
    music_slider = HSlider.new()
    music_slider.name = "MusicVolume"
    music_slider.max_value = 100
    music_slider.step = 1
    music_slider.value = audio.music_volume * 100
    music_slider.custom_minimum_size = Vector2(80, 40)
    music_slider.tooltip_text = "Volume da musica"
    audio_row.add_child(music_slider)
    var effects_label := Label.new()
    effects_label.text = "EFEITOS"
    effects_label.add_theme_font_size_override("font_size", 14)
    audio_row.add_child(effects_label)
    effects_slider = HSlider.new()
    effects_slider.name = "EffectsVolume"
    effects_slider.max_value = 100
    effects_slider.step = 1
    effects_slider.value = audio.effects_volume * 100
    effects_slider.custom_minimum_size = Vector2(80, 40)
    effects_slider.tooltip_text = "Volume dos efeitos"
    audio_row.add_child(effects_slider)
    mute_button = _button("MUDO" if audio.muted else "SOM")
    mute_button.add_theme_font_size_override("font_size", 16)
    mute_button.reparent(audio_row)
    mute_button.pressed.connect(func():
        audio.set_muted(not audio.muted)
        mute_button.text = "MUDO" if audio.muted else "SOM")
    music_slider.value_changed.connect(func(value: float): audio.set_levels(value / 100, effects_slider.value / 100))
    effects_slider.value_changed.connect(func(value: float): audio.set_levels(music_slider.value / 100, value / 100))
    resume = _button("CONTINUAR")
    resume.reparent(box)
    resume.custom_minimum_size.y = 64
    resume.pressed.connect(func(): pause_requested.emit())
    restart_button = _button("REINICIAR BASE")
    restart_button.reparent(box)
    restart_button.custom_minimum_size.y = 64
    restart_button.pressed.connect(func(): restart_requested.emit())
    overlay.hide()
    toast = _label("", 21, Color(1, 0.8, 0.3))
    toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast.add_theme_color_override("font_shadow_color", Color.BLACK)
    toast.add_theme_constant_override("shadow_outline_size", 4)
    navigation = _label("", 17, Color(0.55, 1, 0.65))
    navigation.add_theme_color_override("font_shadow_color", Color.BLACK)
    navigation.add_theme_constant_override("shadow_outline_size", 5)
    credit_text = _label("0", 20, Color(1, 0.85, 0.35))
    kill_popup = _label("", 38, Color(1, 0.9, 0.5))
    kill_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    kill_popup.add_theme_color_override("font_shadow_color", Color(0.05, 0.08, 0.1))
    kill_popup.add_theme_constant_override("shadow_outline_size", 7)
    combo_meter = ProgressBar.new()
    combo_meter.max_value = 4
    combo_meter.show_percentage = false
    combo_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for entry in [["background", Color(0.03, 0.07, 0.1, 0.85)], ["fill", Color(0.1, 0.85, 1)]]:
        var meter_style := StyleBoxFlat.new()
        meter_style.bg_color = entry[1]
        meter_style.set_corner_radius_all(3)
        combo_meter.add_theme_stylebox_override(entry[0], meter_style)
    root.add_child(combo_meter)
    xp_panel = Panel.new()
    xp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    xp_panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.065, 0.095, 0.94), Color(0.18, 0.55, 0.63)))
    root.add_child(xp_panel)
    xp_text = _label("FÚRIA  •  XP 0 / 100", 17, Color(0.55, 0.93, 1))
    xp_meter = ProgressBar.new()
    xp_meter.show_percentage = false
    xp_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for entry in [["background", Color(0.03, 0.09, 0.13)], ["fill", Color(0.18, 0.84, 0.95)]]:
        var meter_style := StyleBoxFlat.new()
        meter_style.bg_color = entry[1]
        meter_style.set_corner_radius_all(4)
        xp_meter.add_theme_stylebox_override(entry[0], meter_style)
    root.add_child(xp_meter)
    frenzy_text = _label("", 18, Color(1, 0.82, 0.25))
    frenzy_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    results = preload("res://scripts/stage_results.gd").new()
    root.add_child(results)
    results.replay_requested.connect(func(): restart_requested.emit())
    rotation_panel = Panel.new()
    root.add_child(rotation_panel)
    rotation_panel.add_theme_stylebox_override("panel", _style(Color(0.025, 0.065, 0.1, 0.99), Color(0.1, 0.5, 0.65)))
    rotation_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    rotation_label = Label.new()
    rotation_label.text = "PROJECT: DEADLIGHT\n\nGIRE O CELULAR\n\nJogue na horizontal"
    rotation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rotation_label.add_theme_font_size_override("font_size", 28)
    rotation_panel.add_child(rotation_label)
    fullscreen_button = _button("TELA CHEIA")
    fullscreen_button.reparent(rotation_panel)
    fullscreen_button.pressed.connect(_fullscreen)
    power_banner = preload("res://scripts/power_banner.gd").new()
    root.add_child(power_banner)
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
    portrait_mode = portrait
    art.health_rect = Rect2(94, 18, 190, 38)
    art.ammo_rect = Rect2(area.x - 200, 18, 182, 44)
    art.mission_rect = Rect2(300, 18, minf(240, maxf(160, area.x - 720)), 34)
    art.credit_rect = Rect2(art.mission_rect.end.x + 12, 18, 92, 34)
    xp_panel.position = Vector2(300, 63)
    xp_panel.size = Vector2(240, 48)
    xp_text.position = xp_panel.position + Vector2(12, 4)
    xp_text.size = Vector2(216, 24)
    xp_meter.position = xp_panel.position + Vector2(12, 32)
    xp_meter.size = Vector2(216, 6)
    frenzy_text.position = Vector2(270, 118)
    frenzy_text.size = Vector2(300, 54)
    captain.hide()
    kills_text.hide()
    mission_title.show()
    mission_title.position = Vector2(96, 65)
    mission_title.add_theme_font_size_override("font_size", 16)
    life.position = art.health_rect.position + Vector2(98, 7)
    life.add_theme_font_size_override("font_size", 19)
    life.add_theme_color_override("font_color", Color.WHITE)
    ammo_icon.position = art.ammo_rect.position + Vector2(9, 6)
    ammo_icon.size = Vector2(43, 28)
    reload_meter.position = art.ammo_rect.position + Vector2(9, 38)
    reload_meter.size = Vector2(art.ammo_rect.size.x - 18, 4)
    for index in range(weapon_buttons.size()):
        weapon_buttons[index].position = Vector2(22 + index * 82, area.y - 264)
        weapon_buttons[index].size = Vector2(72, 68)
    ammo_text.position = art.ammo_rect.position + Vector2(60, 6)
    ammo_text.add_theme_font_size_override("font_size", 24)
    credit_text.position = art.credit_rect.position + Vector2(37, 5)
    objective.position = art.mission_rect.position + Vector2(10, 5)
    objective.size = Vector2(art.mission_rect.size.x - 20, 26)
    objective.add_theme_font_size_override("font_size", 17)
    progress.position = art.mission_rect.position + Vector2(10, 29)
    progress.size = Vector2(art.mission_rect.size.x - 20, 4)
    pause_button.position = Vector2(18, 16)
    pause_button.size = Vector2(60, 64)
    jump_button.position = Vector2(area.x - 126, area.y - 264)
    jump_button.size = Vector2(104, 76)
    overlay.position = area * 0.5 - Vector2(minf(460, area.x - 32), 440) * 0.5
    overlay.size = Vector2(minf(460, area.x - 32), 440)
    toast.position = Vector2(20, area.y - 340)
    toast.size = Vector2(area.x - 40, 32)
    kill_popup.position = Vector2(area.x - 280, 100)
    kill_popup.size = Vector2(230, 100)
    combo_meter.position = Vector2(area.x - 250, 194)
    combo_meter.size = Vector2(200, 6)
    rotation_panel.visible = portrait_mode
    rotation_label.position = Vector2(16, area.y * 0.5 - 160)
    rotation_label.size = Vector2(area.x - 32, 250)
    fullscreen_button.position = Vector2(area.x * 0.5 - 120, area.y * 0.5 + 100)
    fullscreen_button.size = Vector2(240, 68)
    controls.enabled = not portrait_mode and not overlay.visible and not results.visible
    if portrait_mode:
        controls.reset()
    orientation_changed.emit(portrait_mode)
    if results.visible:
        _hide_game_ui()
    art.queue_redraw()
    controls.queue_redraw()

func _request_jump() -> void:
    if is_instance_valid(player) and not overlay.visible and not get_tree().paused:
        player.request_jump()

func _process(delta: float) -> void:
    if results.visible:
        return
    if is_instance_valid(player):
        reload_meter.visible = player.weapon.reload_time > 0 and not overlay.visible
        reload_meter.value = 1 - player.weapon.reload_time / player.weapon.WEAPONS[player.weapon.selected].reload_seconds
    if is_instance_valid(arcade) and is_instance_valid(player):
        var furious: bool = player.weapon.frenzy_time > 0
        var show_xp := not overlay.visible and not portrait_mode
        xp_panel.visible = show_xp
        xp_meter.visible = show_xp
        xp_text.visible = show_xp
        xp_meter.get_theme_stylebox("fill").bg_color = Color(1, 0.68, 0.12) if furious else Color(0.18, 0.84, 0.95)
        xp_meter.max_value = arcade.FRENZY_DURATION if furious else arcade.xp_required
        xp_meter.value = player.weapon.frenzy_time if furious else arcade.xp
        xp_text.text = "FÚRIA ATIVA  •  %.1fs" % player.weapon.frenzy_time if furious else "FÚRIA  •  XP %d / %d" % [arcade.xp, arcade.xp_required]
        frenzy_text.text = "DANO ×3  •  VELOCIDADE ×1,5\nMUNIÇÃO ILIMITADA" if furious else ""
        frenzy_text.visible = show_xp and furious and not power_banner.visible
    kill_time = maxf(0, kill_time - delta)
    var boosted: bool = is_instance_valid(player) and (player.weapon.overdrive_time > 0 or player.weapon.frenzy_time > 0)
    if is_instance_valid(arcade) and (arcade.chain >= 2 or boosted):
        kill_time = maxf(player.weapon.overdrive_time, player.weapon.frenzy_time) if boosted else arcade.chain_time
        kill_popup.text = "FÚRIA\nTRANCO!" if player.weapon.frenzy_time > 0 else ("TRANCO\nTOTAL!" if boosted else "%d\nCOMBO" % arcade.chain)
    kill_popup.visible = kill_time > 0 and not overlay.visible and not portrait_mode and not power_banner.visible
    kill_popup.modulate.a = minf(1, kill_time * 3)
    combo_meter.visible = kill_popup.visible and is_instance_valid(arcade) and (arcade.chain >= 2 or boosted)
    combo_meter.max_value = 10 if is_instance_valid(player) and player.weapon.frenzy_time > 0 else 4
    combo_meter.value = kill_time
    toast_time = maxf(0, toast_time - delta)
    toast.visible = toast_time > 0 and not overlay.visible and not power_banner.visible
    toast.modulate.a = minf(1, toast_time * 2)
    navigation_timer -= delta
    if navigation_timer > 0 or not is_instance_valid(player) or not is_instance_valid(mission):
        return
    navigation_timer = 0.1
    jump_icon.airborne = not player.is_on_floor()
    jump_icon.queue_redraw()
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
    navigation.text = "%dm" % int(player.global_position.distance_to(target))

func update_status(hp: float, ammo: int, reload_active: bool, kills: int, current_mission: Node) -> void:
    status.text = "BAIRRO 1 v0.10.0  |  BASE DO CAPITAO"
    life.text = "%d" % int(ceil(hp))
    art.health_ratio = hp / 100.0
    art.queue_redraw()
    ammo_text.text = "REC..." if reload_active else "%02d/%d" % [ammo, player.weapon.capacity]
    kills_text.text = "ALIENS  %d" % kills
    mission_title.text = "ELIMINAÇÕES  %d" % kills
    var short_titles := ["ARSENAL", "HELIPONTO", "COMUNICAÇÃO"]
    objective.text = "%d/3  %s" % [mini(current_mission.current + 1, 3), short_titles[mini(current_mission.current, 2)]] if current_mission.current < 3 else "3/3  BASE SEGURA"
    if current_mission.contested:
        objective.text += "  !"
    progress.visible = current_mission.progress > 0 or current_mission.contested
    progress.value = current_mission.progress
    details.text = "VIDA %d/100   •   ALIENS %d\n" % [int(ceil(hp)), kills]
    details.text += "BÔNUS: 12 ALIENS  %d/12\n" % mini(kills, 12)
    for index in range(3):
        var mark := "[OK]" if index < current_mission.current else "[  ]"
        details.text += "%s %s\n" % [mark, short_titles[index]]

func notify(text: String) -> void:
    toast.text = text
    toast_time = 2.2

func show_overlay(text: String, paused: bool = false) -> void:
    outcome.text = text
    if paused:
        call_deferred("_report_audio_controls")
    resume.visible = paused
    overlay.show()
    jump_button.hide()
    for button in weapon_buttons:
        button.hide()
    controls.enabled = false
    controls.reset()

func hide_overlay() -> void:
    overlay.hide()
    jump_button.show()
    for button in weapon_buttons:
        button.show()
    controls.enabled = not portrait_mode

func flash() -> void:
    damage_flash.color.a = 0.1
    create_tween().tween_property(damage_flash, "color:a", 0.0, 0.25)

func _input(event: InputEvent) -> void:
    if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
        audio.activate()
    if results.visible and event.is_action_pressed("ui_accept") and not event.is_echo():
        restart_requested.emit()
        get_viewport().set_input_as_handled()
        return
    # Handle Escape before GUI focus can consume it, including while paused.
    if event.is_action_pressed("ui_cancel"):
        pause_requested.emit()
        get_viewport().set_input_as_handled()
        return
    # Sliders handle native touch directly, without enabling emulated mouse.
    if event is InputEventScreenDrag and event.index == audio_drag_id and is_instance_valid(audio_drag_slider):
        _drag_audio(event.position)
        get_viewport().set_input_as_handled()
        return
    if event is InputEventScreenTouch:
        if not event.pressed and event.index == audio_drag_id:
            audio_drag_id = -1
            audio_drag_slider = null
            audio.play("ui")
            get_viewport().set_input_as_handled()
            return
        if event.pressed and overlay.visible:
            for slider in [music_slider, effects_slider]:
                if slider.get_global_rect().grow(8).has_point(event.position):
                    audio_drag_id = event.index
                    audio_drag_slider = slider
                    _drag_audio(event.position)
                    get_viewport().set_input_as_handled()
                    return
    # Native touch routing, independent of emulated mouse input and joystick IDs.
    if not event is InputEventScreenTouch:
        return
    if event.pressed:
        for button in [fullscreen_button] if portrait_mode else [pause_button, resume, restart_button, mute_button, results.replay_button] + weapon_buttons:
            if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
                touch_buttons[event.index] = button
                if button in weapon_buttons:
                    _request_weapon(weapon_buttons.find(button))
                get_viewport().set_input_as_handled()
                return
    elif touch_buttons.has(event.index):
        var button: Button = touch_buttons[event.index]
        touch_buttons.erase(event.index)
        get_viewport().set_input_as_handled()
        if is_instance_valid(button) and button not in weapon_buttons and button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
            button.pressed.emit()

func show_kills(chain: int) -> void:
    kill_popup.text = "%d\nALIENS" % chain
    kill_time = 1.5

func show_credits(value: int) -> void:
    credit_text.text = str(value)

func _fullscreen() -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("(function(){var el=document.documentElement;var p=el.requestFullscreen?el.requestFullscreen():null;if(p&&p.then){p.then(function(){if(screen.orientation&&screen.orientation.lock){screen.orientation.lock('landscape').catch(function(){});}}).catch(function(){});}})()")
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _drag_audio(point: Vector2) -> void:
    var rect := audio_drag_slider.get_global_rect()
    audio_drag_slider.value = clampf((point.x - rect.position.x) / maxf(1, rect.size.x), 0, 1) * 100

func _report_audio_controls() -> void:
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    if not overlay.visible:
        return
    var area := get_viewport().get_visible_rect().size
    var mute_center := mute_button.get_global_rect().get_center() / area
    var music_rect := music_slider.get_global_rect()
    var effects_rect := effects_slider.get_global_rect()
    print("DEADLIGHT_AUDIO_CONTROLS " + JSON.stringify({
        "mute": [mute_center.x, mute_center.y],
        "music": [music_rect.position.x / area.x, music_rect.position.y / area.y, music_rect.size.x / area.x, music_rect.size.y / area.y],
        "effects": [effects_rect.position.x / area.x, effects_rect.position.y / area.y, effects_rect.size.x / area.x, effects_rect.size.y / area.y]
    }))
    _report_combat_target(area)

func _report_combat_target(area: Vector2) -> void:
    # Read-only screen coordinates let browser tests aim with actual mouse input.
    var camera := get_viewport().get_camera_3d()
    for canister in get_tree().get_nodes_in_group("explosives"):
        var point: Vector3 = canister.global_position + Vector3.UP * 1.05
        if canister.armed or camera.is_position_behind(point):
            continue
        var screen := camera.unproject_position(point)
        var normalized := screen / area
        if normalized.x > 0.06 and normalized.x < 0.94 and normalized.y > 0.22 and normalized.y < 0.74:
            if not jump_button.get_global_rect().has_point(screen):
                print("DEADLIGHT_COMBAT_TARGET " + JSON.stringify([normalized.x, normalized.y]))
                return
    print("DEADLIGHT_COMBAT_NO_TARGET player=%s" % player.global_position)

func _request_weapon(index: int) -> void:
    if is_instance_valid(player) and not overlay.visible and not results.visible and not portrait_mode:
        player.weapon.select_weapon(index)

func show_weapon(index: int) -> void:
    ammo_icon.weapon_index = index
    ammo_icon.queue_redraw()
    for slot in range(weapon_buttons.size()):
        var selected := slot == index
        var style := _style(Color(0.07, 0.17, 0.22, 0.95), Color(0.15, 0.85, 1) if selected else Color(0.35, 0.46, 0.53))
        style.set_content_margin_all(2)
        weapon_buttons[slot].add_theme_stylebox_override("normal", style)
        weapon_buttons[slot].modulate.a = 1 if selected else 0.65

func _hide_game_ui() -> void:
    for node in [xp_panel, xp_meter, xp_text, frenzy_text, art, captain, life, ammo_text, kills_text, mission_title, objective, progress, pause_button, jump_button, navigation, credit_text, kill_popup, combo_meter, toast, ammo_icon, reload_meter, controls] + weapon_buttons:
        node.hide()
    controls.enabled = false
    controls.reset()

func show_result(summary: Dictionary) -> void:
    outcome.text = "BASE PROTEGIDA!" if summary.won else "BASE INVADIDA!"
    overlay.hide()
    _hide_game_ui()
    results.present(summary)

func show_power_activation(_duration: float, major: bool) -> void:
    power_banner.player = player
    power_banner.trigger(major)
