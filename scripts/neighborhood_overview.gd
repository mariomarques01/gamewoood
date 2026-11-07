extends CanvasLayer
const L = preload("res://scripts/neighborhood_layout.gd")
var district: Node3D
var camera: Camera3D
var panel: Control
var open := false
var map_button: Button
var close_button: Button
var objective_labels: Array[Label] = []
var task_labels: Array[Label] = []
var current_task: Label
var legend: PanelContainer
var player_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 12
    camera = Camera3D.new()
    district.add_child(camera)
    camera.position = Vector3(32,145,165)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.keep_aspect = Camera3D.KEEP_WIDTH
    camera.size = 225
    camera.look_at(Vector3(19,0,-4))
    camera.near = 10
    camera.far = 450
    map_button = Button.new()
    map_button.text = "MAPA"
    map_button.tooltip_text = "Visão geral do bairro (M)"
    map_button.add_theme_font_override("font",preload("res://assets/fonts/LilitaOne-Regular.ttf"))
    map_button.pressed.connect(toggle)
    add_child(map_button)
    panel = Control.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(panel)
    var title := Label.new()
    title.text = "PROJECT: DEADLIGHT\nMAPA — BAIRRO 1\nBASE DO CAPITÃO  •  +5 QUARTEIRÕES"
    title.position = Vector2(20,20)
    title.add_theme_font_override("font",preload("res://assets/fonts/LilitaOne-Regular.ttf"))
    title.add_theme_font_size_override("font_size",20)
    title.add_theme_color_override("font_shadow_color",Color.BLACK)
    title.add_theme_constant_override("shadow_offset_x",2)
    title.add_theme_constant_override("shadow_offset_y",2)
    panel.add_child(title)
    legend = PanelContainer.new()
    legend.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
    legend.offset_left = -330
    legend.offset_right = -12
    legend.offset_top = 20
    legend.offset_bottom = -62
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.02, 0.055, 0.085, 0.97)
    style.border_color = Color(0.2, 0.9, 0.65)
    style.set_border_width_all(2)
    style.set_content_margin_all(14)
    style.set_corner_radius_all(12)
    legend.add_theme_stylebox_override("panel", style)
    panel.add_child(legend)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    legend.add_child(box)
    _legend_label(box, "COMO VENCER A PARTIDA", 20)
    _legend_label(box, "Complete as 3 áreas verdes.\nEm cada uma, fique 3s sem inimigos por perto.", 16)
    current_task = _legend_label(box, "", 17)
    for index in range(3):
        task_labels.append(_legend_label(box, "", 17))
        var label := Label.new()
        label.size = Vector2(230, 56)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_override("font", preload("res://assets/fonts/LilitaOne-Regular.ttf"))
        label.add_theme_font_size_override("font_size", 18)
        label.add_theme_color_override("font_outline_color", Color(0.015, 0.04, 0.07))
        label.add_theme_constant_override("outline_size", 6)
        panel.add_child(label)
        objective_labels.append(label)
    player_label = Label.new()
    player_label.text = "VOCÊ"
    player_label.add_theme_font_size_override("font_size", 18)
    player_label.add_theme_color_override("font_color", Color(0.25, 0.85, 1))
    player_label.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.07))
    player_label.add_theme_constant_override("outline_size", 6)
    panel.add_child(player_label)
    var close := Button.new()
    close_button = close
    close.text = "VOLTAR AO JOGO  [M]"
    close.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    close.position = Vector2(-242,-48)
    close.size = Vector2(230,38)
    close.pressed.connect(toggle)
    panel.add_child(close)
    panel.hide()

func _process(_delta: float) -> void:
    var expected: Camera3D = camera if open else district.player.get_node("Camera3D")
    if get_viewport().get_camera_3d() != expected:
        expected.make_current()
    var size := get_viewport().get_visible_rect().size
    if open:
        var missions = district.missions
        current_task.text = "%s PARA VENCER" % missions.remaining_text()
        for index in range(objective_labels.size()):
            var state := "CONCLUÍDA" if index < missions.current else ("ATUAL" if index == missions.current else "PRÓXIMA")
            var tint := Color(0.35, 1, 0.7) if index <= missions.current else Color(0.8, 0.87, 0.9)
            task_labels[index].text = "%d  %s\n%s" % [index + 1, missions.TITLES[index], state]
            task_labels[index].add_theme_color_override("font_color", tint)
            objective_labels[index].text = "%d  %s\n%s" % [index + 1, missions.NAMES[index], state]
            objective_labels[index].add_theme_color_override("font_color", tint)
            var point := camera.unproject_position(L.OBJECTIVES[index] + Vector3.UP * 2) - Vector2(115, 0)
            objective_labels[index].position = point.clamp(Vector2(12, 116), Vector2(size.x - 570, size.y - 110))
        player_label.position = camera.unproject_position(district.player.global_position + Vector3.UP) + Vector2(0, 22)
    map_button.position = Vector2(size.x-86,78)
    map_button.size = Vector2(70,30)
    map_button.visible = not open and not district.ended and not get_tree().paused

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        var button := close_button if open else map_button
        if button.visible and button.get_global_rect().has_point(event.position):
            toggle()
            get_viewport().set_input_as_handled()
            return
    if open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        toggle()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M and not district.ended:
        toggle()
        get_viewport().set_input_as_handled()

func toggle() -> void:
    if district.ended:
        return
    open = not open
    panel.visible = open
    district.hud.visible = not open
    district.map_open = open
    district.hud.controls.reset()
    district.hud.controls.enabled = not open and not district.orientation_blocked
    district._sync_pause()
    if open:
        district.get_node("DirectionalLight3D").directional_shadow_max_distance = 200
        camera.current = true
    else:
        district.get_node("DirectionalLight3D").directional_shadow_max_distance = 48
        district.player.get_node("Camera3D").current = true

func _legend_label(parent: Node, text: String, pixels: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_override("font", preload("res://assets/fonts/LilitaOne-Regular.ttf"))
    label.add_theme_font_size_override("font_size", pixels)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label
