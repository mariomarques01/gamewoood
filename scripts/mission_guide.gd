extends PanelContainer
const Missions = preload("res://scripts/mission_manager.gd")
const FONT = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const TEXT_FONT = preload("res://assets/fonts/Nunito-ExtraBold.ttf")
var heading: Label
var status_label: Label
var instruction: Label
var compass: Control
var meter: ProgressBar
var checklist: Array[Label] = []
var checklist_row: HBoxContainer
var last_report := ""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size.y = 124
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.018, 0.055, 0.09, 0.92)
    style.border_color = Color(0.2, 0.82, 0.7, 0.85)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(10)
    add_theme_stylebox_override("panel", style)
    var box := VBoxContainer.new()
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_theme_constant_override("separation", 3)
    add_child(box)
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 8)
    box.add_child(row)
    compass = preload("res://scripts/objective_compass.gd").new()
    row.add_child(compass)
    heading = _label(row, 20, Color(1, 0.85, 0.3))
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label = _label(box, 16, Color(0.5, 1, 0.8))
    instruction = _label(box, 15, Color(0.94, 0.97, 1))
    meter = ProgressBar.new()
    meter.custom_minimum_size.y = 5
    meter.max_value = 1
    meter.show_percentage = false
    meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for pair in [["background", Color(0.08, 0.18, 0.22)], ["fill", Color(0.2, 0.9, 0.65)]]:
        var bar := StyleBoxFlat.new()
        bar.bg_color = pair[1]
        bar.set_corner_radius_all(3)
        meter.add_theme_stylebox_override(pair[0], bar)
    box.add_child(meter)
    checklist_row = HBoxContainer.new()
    checklist_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(checklist_row)
    for index in range(3):
        var label := _label(checklist_row, 11, Color.WHITE)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        checklist.append(label)
    hide()

func _label(parent: Node, pixels: int, color: Color) -> Label:
    var label := Label.new()
    label.add_theme_font_override("font", FONT if pixels >= 20 else TEXT_FONT)
    label.add_theme_font_size_override("font_size", pixels)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label

func update_mission(mission: Node, player: Node3D, camera: Camera3D, defense_complete: bool) -> void:
    if not mission.active or mission.current >= Missions.NAMES.size() or not is_instance_valid(camera):
        hide()
        return
    var state: Dictionary = mission.guidance()
    var expanded: bool = defense_complete or state.nearby
    instruction.visible = expanded
    meter.visible = expanded
    checklist_row.visible = expanded
    custom_minimum_size.y = 124 if expanded else 80
    size.y = custom_minimum_size.y
    heading.text = "%d/3  %s" % [mission.current + 1, Missions.TITLES[mission.current]]
    status_label.text = state.status
    instruction.text = state.instruction
    status_label.show()
    meter.value = mission.progress
    compass.arrived = state.nearby
    compass.contested = mission.contested
    var target: Vector3 = Missions.POSITIONS[mission.current] + Vector3.UP
    var projected := camera.unproject_position(target) - camera.unproject_position(player.global_position + Vector3.UP)
    compass.direction = -projected if camera.is_position_behind(target) else projected
    compass.queue_redraw()
    for index in range(checklist.size()):
        checklist[index].text = "%s %s" % ["OK" if index < mission.current else str(index + 1), Missions.NAMES[index]]
        checklist[index].add_theme_color_override("font_color", Color(0.35, 1, 0.7) if index < mission.current else (Color(1, 0.85, 0.3) if index == mission.current else Color(0.6, 0.7, 0.75)))
    show()
    var key := "%d:%s:%s" % [mission.current, state.kind, defense_complete]
    if key != last_report:
        last_report = key
        print("DEADLIGHT_OBJECTIVE_GUIDE " + JSON.stringify({"objective": mission.current + 1, "title": heading.text, "status": state.status, "instruction": state.instruction, "state": state.kind, "defense_complete": defense_complete}))
