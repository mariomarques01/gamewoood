extends RefCounted
# Keep reward rules independent from presentation and save side effects.
static func calculate(won: bool, kills: int, seconds: float, hp: float, collected: int, objectives: int) -> Dictionary:
    var stars := 0
    if won:
        stars = 1 + (1 if kills >= 12 else 0) + (1 if hp >= 50 else 0)
    var bonus := 100 + (stars - 1) * 25 if won else 0
    return {"won": won, "kills": kills, "seconds": maxf(0, seconds), "hp": hp,
        "objectives": objectives, "stars": stars, "collected": maxi(0, collected),
        "bonus": bonus, "earned": maxi(0, collected) + bonus}
