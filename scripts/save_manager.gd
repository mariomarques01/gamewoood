extends Node
const PATH := "user://deadlight.cfg"
var best_kills := 0
var credits := 0
var best_stars := 0
var district_unlocked := false

func _ready() -> void:
    var config := ConfigFile.new()
    if config.load(PATH) == OK:
        best_stars = clampi(int(config.get_value("progress", "best_stars", 0)), 0, 3)
        credits = int(config.get_value("progress", "credits", 0))
        best_kills = int(config.get_value("progress", "best_kills", 0))
        district_unlocked = bool(config.get_value("progress", "district_one", false))

func record(kills: int, won: bool, collected_credits: int = 0, stars: int = 0) -> void:
    credits += maxi(0, collected_credits)
    if won:
        best_stars = maxi(best_stars, clampi(stars, 0, 3))
    best_kills = maxi(best_kills, kills)
    district_unlocked = district_unlocked or won
    var config := ConfigFile.new()
    config.set_value("progress", "credits", credits)
    config.set_value("progress", "best_stars", best_stars)
    config.set_value("progress", "best_kills", best_kills)
    config.set_value("progress", "district_one", district_unlocked)
    var result := config.save(PATH)
    if result != OK:
        push_warning("Progress could not be saved: %s" % error_string(result))
