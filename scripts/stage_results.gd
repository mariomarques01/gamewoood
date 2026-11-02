extends Control
signal replay_requested
var summary: Dictionary = {}
var replay_button: Button
var title: Label
var subtitle: Label
var stats: Label
var rewards: Label
var stars: Control
var card: PanelContainer
var age := 0.0

func _label(text: String, font_size: int, parent: Node) -> Label:
    var label := Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.92, 0.97, 1))
    parent.add_child(label)
    return label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title = _label("MISSAO\nCONCLUIDA!", 44, self)
    title.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.07))
    title.add_theme_constant_override("shadow_outline_size", 7)
    subtitle = _label("BASE DO CAPITAO", 18, self)
    card = PanelContainer.new()
    add_child(card)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.065, 0.11, 0.94)
    style.border_color = Color(0.15, 0.85, 1)
    style.set_border_width_all(2)
    style.set_corner_radius_all(14)
    style.set_content_margin_all(14)
    card.add_theme_stylebox_override("panel", style)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    card.add_child(box)
    _label("RELATORIO DA OPERACAO", 20, box)
    stars = preload("res://scripts/result_stars.gd").new()
    stars.custom_minimum_size = Vector2(270, 48)
    box.add_child(stars)
    stats = _label("", 18, box)
    rewards = _label("", 20, box)
    rewards.add_theme_color_override("font_color", Color(1, 0.78, 0.2))
    var criteria := _label("MEDALHAS: MISSAO / 12 ALIENS / VIDA 50+", 11, box)
    criteria.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    replay_button = Button.new()
    replay_button.text = "REPETIR FASE"
    replay_button.custom_minimum_size.y = 52
    replay_button.focus_mode = Control.FOCUS_NONE
    replay_button.add_theme_font_size_override("font_size", 22)
    replay_button.add_theme_stylebox_override("normal", style)
    box.add_child(replay_button)
    replay_button.pressed.connect(func(): replay_requested.emit())
    resized.connect(_layout)
    hide()

func present(result: Dictionary) -> void:
    summary = result.duplicate()
    age = 0
    title.text = "MISSAO\nCONCLUIDA!" if summary.won else "BASE\nINVADIDA!"
    subtitle.text = "BAIRRO 1  •  PROGRESSO SALVO" if summary.won else "O CAPITAO VOLTA JA..."
    stars.stars = summary.stars
    stars.queue_redraw()
    var seconds := int(summary.seconds)
    stats.text = "OBJETIVOS   %d/3\nALIENS       %d\nTEMPO        %02d:%02d\nCOLETADOS    +%d" % [summary.objectives, summary.kills, seconds / 60, seconds % 60, summary.collected]
    _update_rewards()
    show()
    _layout()
    queue_redraw()
    print("DEADLIGHT_FINALE " + JSON.stringify(summary))

func _update_rewards() -> void:
    if summary.is_empty():
        return
    var shown := int(round(summary.earned * minf(1, age / 0.9)))
    rewards.text = "BONUS MISSAO  +%d\nCREDITOS GANHOS  %d" % [summary.bonus, shown]

func _process(delta: float) -> void:
    if not visible or summary.is_empty():
        return
    age += delta
    if age < 1.1:
        _update_rewards()

func _layout() -> void:
    if not is_instance_valid(card):
        return
    title.position = Vector2(28, 58)
    title.size = Vector2(size.x * 0.47, 136)
    subtitle.position = Vector2(30, 26)
    card.position = Vector2(size.x * 0.54, 30)
    card.size = Vector2(size.x * 0.43 - 16, 420)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.035, 0.065, 0.25))
