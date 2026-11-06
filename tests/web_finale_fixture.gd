extends Node
# Exported only by tools/export_finale_fixture.py, never in the shipped game.
func _ready() -> void:
    var district = load("res://scenes/main.tscn").instantiate()
    get_tree().root.add_child.call_deferred(district)
    await get_tree().process_frame
    await get_tree().physics_frame
    district.spawner.active = false
    district.player.set_physics_process(false)
    district.score = 12
    district.arcade.credits = 35
    district.run_seconds = 95
    var wallet_before: int = district.save.credits
    for index in range(3):
        district.player.position = district.missions.POSITIONS[index]
        district.missions._physics_process(3.1)
    assert(district.ended and district.hud.results.visible)
    assert(district.last_result.earned == 185 and district.save.credits == wallet_before + 185)
    district._finish(true)
    assert(district.save.credits == wallet_before + 185)
    var saved := ConfigFile.new()
    assert(saved.load("user://deadlight.cfg") == OK)
    assert(int(saved.get_value("progress", "best_stars", 0)) == 3)
    await get_tree().create_timer(1.1).timeout
    await RenderingServer.frame_post_draw
    var view := get_viewport().get_visible_rect().size
    var result = district.hud.results
    assert(result.card.get_global_rect().end.y < view.y)
    var center: Vector2 = result.replay_button.get_global_rect().get_center() / view
    print("DEADLIGHT_WEB_FINALE_FIXTURE " + JSON.stringify({"menu": [result.menu_button.get_global_rect().get_center().x / view.x, result.menu_button.get_global_rect().get_center().y / view.y], "replay": [center.x, center.y], "stars": 3, "earned": 185}))
    # Replaying reloads the real main scene, not this deterministic fixture.
    get_tree().current_scene = district
    queue_free()
