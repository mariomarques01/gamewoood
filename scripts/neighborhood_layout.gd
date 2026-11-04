extends RefCounted
# One source of truth for geometry, objectives, map legend and spawn locations.
const HALF_SIZE := Vector2(74, 64)
const PLAYER_START := Vector3(0, 0, 1)
const BLOCK_CENTERS := [Vector3(0, 0, -24), Vector3(-42, 0, -24), Vector3(42, 0, -24), Vector3(-42, 0, 24), Vector3(0, 0, 24), Vector3(42, 0, 24)]
const BLOCK_NAMES := ["BASE DO CAPITÃO", "ARSENAL", "HELIPONTO", "OFICINA", "QUARTEL GENERAL", "CENTRO DE SUPRIMENTOS"]
const BLOCK_DESCRIPTIONS := ["Comando e operações", "Armas e equipamentos", "Extração e missões aéreas", "Manutenção e reparos", "Planejamento e inteligência", "Logística e distribuição"]
const OBJECTIVES := [Vector3(-42, 0, -14), Vector3(42, 0, -10), Vector3(-12, 0, -34)]
const SERVICE_POINTS := [Vector3(-42, 0, 35), Vector3(42, 0, 35)]
const CANISTERS := [Vector3(-10, 0, -3), Vector3(10, 0, -3), Vector3(-22, 0, -14), Vector3(22, 0, -14), Vector3(22, 0, 24), Vector3(-22, 0, 24)]
const SPAWN_POINTS := [Vector3(-21, 0, 1), Vector3(21, 0, 1), Vector3(-42, 0, 1), Vector3(42, 0, 1), Vector3(0, 0, -48), Vector3(0, 0, 48), Vector3(-21, 0, -24), Vector3(21, 0, -24), Vector3(-21, 0, 24), Vector3(21, 0, 24), Vector3(-63, 0, -24), Vector3(63, 0, -24), Vector3(-63, 0, 24), Vector3(63, 0, 24), Vector3(0, 0, -10), Vector3(-13, 0, -30)]

static func in_bounds(point: Vector3) -> bool:
    return point.is_finite() and absf(point.x) < HALF_SIZE.x - 1 and absf(point.z) < HALF_SIZE.y - 1
