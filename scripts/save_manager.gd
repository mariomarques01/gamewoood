extends Node
const PATH := "user://deadlight.cfg"
var best_kills := 0
var credits := 0
var best_stars := 0
var district_unlocked := false
var best_wave := 0
var equipped := 1
var upgrades: Dictionary = {}
var tutorial_seen := false
var storage_path := PATH
var last_error := OK

func _ready() -> void:
    var config := ConfigFile.new()
    if config.load(storage_path) == OK:
        best_stars = clampi(int(config.get_value("progress", "best_stars", 0)), 0, 3)
        credits = maxi(0, int(config.get_value("progress", "credits", 0)))
        best_kills = int(config.get_value("progress", "best_kills", 0))
        district_unlocked = bool(config.get_value("progress", "district_one", false))
        best_wave = clampi(int(config.get_value("progress", "best_wave", 0)), 0, 3)
        equipped = clampi(int(config.get_value("arsenal", "equipped", 1)), 0, 1)
        tutorial_seen = bool(config.get_value("progress", "tutorial_seen", false))
        for index in range(2):
            for kind in ["damage", "reload"]:
                var key := "%d_%s" % [index, kind]
                upgrades[key] = clampi(int(config.get_value("arsenal", key, 0)), 0, 3)

func record(kills: int, won: bool, collected_credits: int = 0, stars: int = 0) -> bool:
    credits += maxi(0, collected_credits)
    if won:
        best_stars = maxi(best_stars, clampi(stars, 0, 3))
    best_kills = maxi(best_kills, kills)
    district_unlocked = district_unlocked or won
    return persist()

func persist() -> bool:
    var config := ConfigFile.new()
    config.set_value("progress", "credits", credits)
    config.set_value("progress", "best_stars", best_stars)
    config.set_value("progress", "best_kills", best_kills)
    config.set_value("progress", "district_one", district_unlocked)
    config.set_value("progress", "best_wave", best_wave)
    config.set_value("progress", "tutorial_seen", tutorial_seen)
    config.set_value("arsenal", "equipped", equipped)
    for key in upgrades:
        config.set_value("arsenal", key, upgrades[key])
    var temporary := storage_path + ".tmp"
    var result := config.save(temporary)
    if result == OK:
        result = DirAccess.rename_absolute(temporary, storage_path)
    last_error = result
    if result != OK:
        push_warning("Progress could not be saved: %s" % error_string(result))
    return result == OK

func upgrade_level(index: int, kind: String) -> int:
    return int(upgrades.get("%d_%s" % [index, kind], 0))

func upgrade_cost(index: int, kind: String) -> int:
    return 75 * (upgrade_level(index, kind) + 1)

func buy_upgrade(index: int, kind: String) -> bool:
    if index not in [0, 1] or kind not in ["damage", "reload"] or upgrade_level(index, kind) >= 3:
        return false
    var cost := upgrade_cost(index, kind)
    if credits < cost:
        return false
    var key := "%d_%s" % [index, kind]
    var previous := upgrade_level(index, kind)
    credits -= cost
    upgrades[key] = previous + 1
    if persist():
        return true
    credits += cost
    upgrades[key] = previous
    return false

func equip(index: int) -> bool:
    if index not in [0, 1]:
        return false
    var previous := equipped
    equipped = index
    if persist():
        return true
    equipped = previous
    return false

func mark_tutorial_seen() -> void:
    tutorial_seen = true
    if not persist():
        tutorial_seen = false
