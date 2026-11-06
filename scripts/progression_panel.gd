extends Control
const FONT = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const WEAPONS = preload("res://scripts/weapon_system.gd").WEAPONS
var progress: Node
var panel: PanelContainer
var balance: Label
var title: Label
var description: Label
var feedback: Label
var equip_button: Button
var damage_button: Button
var reload_button: Button
var close_button: Button
var selectors: Array[Button] = []
var selected := 1
var page := "arsenal"
var pressed: Dictionary = {}

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0, 0.015, 0.035, 0.94)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    panel = PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.06, 0.11)
    style.border_color = Color(0.1, 0.85, 1)
    style.set_border_width_all(3)
    style.set_corner_radius_all(20)
    style.set_content_margin_all(24)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)
    title = _label(box, 32)
    balance = _label(box, 24)
    balance.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    box.add_child(row)
    for index in range(2):
        var button := _button(row, WEAPONS[index].display_name)
        button.toggle_mode = true
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(func():
            selected = index
            feedback.text = ""
            refresh())
        selectors.append(button)
    description = _label(box, 22)
    description.custom_minimum_size = Vector2(660, 90)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    equip_button = _button(box, "")
    equip_button.pressed.connect(func():
        feedback.text = "ARMA EQUIPADA" if progress.equip(selected) else "NÃO FOI POSSÍVEL SALVAR. TENTE NOVAMENTE."
        refresh())
    damage_button = _button(box, "")
    damage_button.pressed.connect(func(): _buy("damage"))
    reload_button = _button(box, "")
    reload_button.pressed.connect(func(): _buy("reload"))
    feedback = _label(box, 18)
    feedback.custom_minimum_size.y = 24
    close_button = _button(box, "VOLTAR")
    close_button.pressed.connect(func():
        pressed.clear()
        hide())
    resized.connect(_layout)
    hide()

func _label(parent: Node, pixels: int) -> Label:
    var label := Label.new()
    label.add_theme_font_override("font", FONT)
    label.add_theme_font_size_override("font_size", pixels)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func _button(parent: Node, text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 52
    button.add_theme_font_override("font", FONT)
    button.add_theme_font_size_override("font_size", 22)
    parent.add_child(button)
    return button

func open(section: String) -> void:
    page = section
    selected = progress.equipped
    feedback.text = ""
    show()
    refresh()
    _layout()
    print("DEADLIGHT_MENU_PROGRESSION ", section)

func _layout() -> void:
    if not is_instance_valid(panel):
        return
    panel.size = Vector2(780, 0)
    panel.position = (get_viewport_rect().size - panel.size) * 0.5
    _report.call_deferred()

func refresh() -> void:
    var achievements := page == "achievements"
    title.text = "CONQUISTAS" if achievements else ("UPGRADES" if page == "upgrades" else "ARSENAL")
    balance.text = "CRÉDITOS: %d" % progress.credits
    for button in selectors:
        button.visible = not achievements
    for button in [equip_button, damage_button, reload_button]:
        button.visible = not achievements
    if achievements:
        description.text = "MELHOR PARTIDA: %d ALIENS\nMEDALHAS DA MISSÃO: %d/3\nONDAS CONCLUÍDAS: %d/3" % [progress.best_kills, progress.best_stars, progress.best_wave]
    else:
        var weapon = WEAPONS[selected]
        var damage: int = progress.upgrade_level(selected, "damage")
        var reload_level: int = progress.upgrade_level(selected, "reload")
        description.text = "%s • DANO %.1f • PENTE %d\nRECARGA %.2fs • %s" % [weapon.display_name, weapon.damage * (1 + damage * 0.1), weapon.capacity, weapon.reload_seconds * (1 - reload_level * 0.1), "PRECISÃO / TIRO FORTE" if selected == 0 else "RAJADAS / ALTA CADÊNCIA"]
        equip_button.text = "EQUIPADA PARA A PRÓXIMA PARTIDA" if progress.equipped == selected else "EQUIPAR PARA A PRÓXIMA PARTIDA"
        equip_button.disabled = progress.equipped == selected
        for pair in [["damage", damage_button, "DANO +10%"], ["reload", reload_button, "RECARGA -10%"]]:
            var level: int = progress.upgrade_level(selected, pair[0])
            var cost: int = progress.upgrade_cost(selected, pair[0])
            pair[1].text = "%s  •  NÍVEL %d/3  •  %s" % [pair[2], level, "MÁXIMO" if level == 3 else "%d CRÉDITOS" % cost]
            pair[1].disabled = level == 3 or progress.credits < cost
        for index in range(2):
            selectors[index].button_pressed = index == selected
    _layout.call_deferred()

func _buy(kind: String) -> void:
    feedback.text = "MELHORIA COMPRADA E SALVA!" if progress.buy_upgrade(selected, kind) else "COMPRA NÃO CONCLUÍDA. CONFIRA SEU SALDO."
    preload("res://scripts/audio_api.gd").play(self, "ui")
    refresh()

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        hide()
        get_viewport().set_input_as_handled()
    if not event is InputEventScreenTouch:
        return
    var buttons: Array = selectors + [equip_button, damage_button, reload_button, close_button]
    if event.pressed:
        for button in buttons:
            if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(event.position):
                pressed[event.index] = button
                break
    elif pressed.has(event.index):
        var button: Button = pressed[event.index]
        pressed.erase(event.index)
        if not button.disabled and button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
            button.pressed.emit()
    get_viewport().set_input_as_handled()

func _report() -> void:
    if not visible:
        return
    var controls := {}
    var area := get_viewport_rect().size
    for pair in [["back", close_button], ["equip", equip_button], ["damage", damage_button], ["reload", reload_button], ["pistol", selectors[0]], ["machine", selectors[1]]]:
        var center: Vector2 = pair[1].get_global_rect().get_center() / area
        controls[pair[0]] = [center.x, center.y]
    print("DEADLIGHT_PROGRESSION_CONTROLS ", JSON.stringify(controls))
