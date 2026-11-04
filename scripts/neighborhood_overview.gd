extends CanvasLayer
const L = preload("res://scripts/neighborhood_layout.gd")
var district: Node3D
var camera: Camera3D
var panel: Control
var open := false
var map_button: Button
var close_button: Button
var block_labels: Array[Label] = []

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
    camera.far = 800
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
    var legend := PanelContainer.new()
    legend.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
    legend.offset_left = -240
    legend.offset_right = -12
    legend.offset_top = 20
    legend.offset_bottom = -62
    panel.add_child(legend)
    var text := Label.new()
    text.text = "QUARTEIRÕES DO BAIRRO 1\n\n"
    for i in range(6):
        text.text += "%d  %s\n%s\n\n" % [i+1,L.BLOCK_NAMES[i],L.BLOCK_DESCRIPTIONS[i]]
    text.text += "PERÍMETRO FORTIFICADO\nTorres de vigia e portão principal\n\nCOSTA\nFalésias, floresta e cachoeiras"
    text.add_theme_font_override("font",preload("res://assets/fonts/LilitaOne-Regular.ttf"))
    text.add_theme_font_size_override("font_size",14)
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    legend.add_child(text)
    for i in range(6):
        var label := Label.new()
        label.text = "%d  %s" % [i+1,L.BLOCK_NAMES[i]]
        label.size = Vector2(180,40)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_override("font",preload("res://assets/fonts/LilitaOne-Regular.ttf"))
        label.add_theme_font_size_override("font_size",14)
        label.add_theme_color_override("font_outline_color",Color(0.015,0.04,0.07))
        label.add_theme_constant_override("outline_size",6)
        panel.add_child(label)
        block_labels.append(label)
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
    var size := get_viewport().get_visible_rect().size
    if open:
        for i in range(block_labels.size()):
            block_labels[i].position = camera.unproject_position(L.BLOCK_CENTERS[i]+Vector3(0,5,6))-Vector2(90,0)
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
