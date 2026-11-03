extends Node
func _ready() -> void:
    var district = load("res://scenes/main.tscn").instantiate()
    add_child(district)
    await get_tree().process_frame
    district.spawner.active = false
    district.arcade.set_physics_process(false)
    district.arcade.xp = 108
    district.arcade.frenzy_level = 6
    district.player.weapon.ammo = 18
    district.hud.show_credits(1005)
    district._update_hud()
    district.hud._process(0)
    district.hud.toast_time = 0
    district.hud.toast.hide()
    print("DEADLIGHT_HUD_FIXTURE_READY")
