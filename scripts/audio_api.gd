extends RefCounted
# Runtime lookup also works in standalone SceneTree tests before autoload globals bind.
static func play(source: Node, cue: String, position: Vector3 = Vector3.INF) -> bool:
    if not source.is_inside_tree():
        return false
    var mixer := source.get_node_or_null("/root/GameAudio")
    return mixer.play(cue, position) if mixer != null else false
