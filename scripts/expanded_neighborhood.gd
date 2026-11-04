extends RefCounted
const L = preload("res://scripts/neighborhood_layout.gd")
const ROAD = Color(0.17, 0.20, 0.25)
const TILE = Color(0.48, 0.5, 0.49)
const WALL = Color(0.47, 0.51, 0.56)
const BLUE = Color(0.12, 0.35, 0.62)
const GOLD = Color(1.0, 0.68, 0.12)
const WHITE = Color(0.89, 0.91, 0.83)

static func build(m: Node3D) -> void:
    m._box(m, Vector3(0,-0.4,0), Vector3(148,0.8,128), TILE, true)
    _coast(m)
    for x in [-63,-21,21,63]:
        m._box(m,Vector3(x,0.025,0),Vector3(8,0.05,106),ROAD)
        for z in range(-44,49,7):
            m._box(m,Vector3(x,0.065,z),Vector3(0.16,0.02,2.6),GOLD)
    for z in [-48,0,48]:
        m._box(m,Vector3(0,0.03,z),Vector3(134,0.06,10),ROAD)
        for x in range(-60,61,7):
            if abs(x+21)<5 or abs(x-21)<5:
                continue
            m._box(m,Vector3(x,0.07,z),Vector3(3,0.02,0.16),GOLD)
        for x in [-63,-21,21,63]:
            for side in [-1,1]:
                for stripe in range(6):
                    m._box(m,Vector3(x-2.7+stripe*1.08,0.085,z+side*7),Vector3(0.65,0.025,3),WHITE)
    for i in range(6):
        var c: Vector3 = L.BLOCK_CENTERS[i]
        _parcel(m,c)
        if i == 0:
            _headquarters(m,c,"BASE DO CAPITÃO",BLUE)
            _pad(m,c+Vector3(0,8.5,-3),6)
            _radio(m,c+Vector3(-9,0,-16))
            m._sphere(c+Vector3(7,10,-5),Vector3(4,4,4),WHITE)
        elif i == 4:
            _headquarters(m,c,"QUARTEL GENERAL",WALL)
            for x in [-12,12]:
                _garden(m,c+Vector3(x,0,11))
        else:
            _hangar(m,c,i)
        if i != 4:
            _garden(m,c+Vector3(-13,0,12))
            _garden(m,c+Vector3(13,0,12))
        for x in [-15,15]:
            _lamp(m,c+Vector3(x,0,16))
    # Supply pallets, loading bays and parking spaces give each forecourt a purpose.
    for c in L.BLOCK_CENTERS:
        for x in [-7,-3,1,5]:
            m._box(m,c+Vector3(x,0.18,15),Vector3(0.1,0.025,4),WHITE)
    for p in [Vector3(-50,0,-12),Vector3(-47,0,-12),Vector3(50,0,33),Vector3(54,0,33)]:
        m._box(m,p+Vector3(0,0.6,0),Vector3(1.6,1.2,1.6),Color(0.42,0.32,0.16),true)
        m._box(m,p+Vector3(0,0.6,0.84),Vector3(0.1,1.2,0.1),GOLD)
    _pad(m,Vector3(42,0.13,-14),7)
    _helicopter(m,Vector3(46,0.3,-18))
    for p in [Vector3(51,0,29),Vector3(52,0,38),Vector3(34,0,38),Vector3(-52,0,-11)]:
        _container(m,p)
    for p in [Vector3(-48,0,34),Vector3(53,0,12),Vector3(-4,0,-48),Vector3(32,0,45)]:
        _truck(m,p)
    for x in [-70,70]:
        m._box(m,Vector3(x,1.7,0),Vector3(0.6,3.4,112),WALL,true)
        for z in [-54,-18,18,54]:
            _tower(m,Vector3(x,0,z))
    m._box(m,Vector3(0,1.7,-56),Vector3(140,3.4,0.6),WALL,true)
    for x in [-39,39]:
        m._box(m,Vector3(x,1.7,56),Vector3(62,3.4,0.6),WALL,true)
    for x in [-9,9]:
        m._box(m,Vector3(x,2,56),Vector3(3,4,4),BLUE,true)
        m._box(m,Vector3(x,4.2,56),Vector3(3.4,0.4,4.4),GOLD)
    for x in range(-6,7,2):
        m._box(m,Vector3(x,1.6,56),Vector3(0.17,3.2,0.2),WALL,true)
    m._box(m,Vector3(0,0.04,59),Vector3(16,0.08,10),ROAD)
    m._sign("PORTÃO PRINCIPAL",Vector3(0,4.5,56),0.018)
    for i in range(3):
        var marker := Node3D.new()
        m.add_child(marker)
        marker.position = L.OBJECTIVES[i]
        m._box(marker,Vector3(0,0.16,0),Vector3(4.8,0.12,4.8),Color(0.1,0.8,0.65))
        m.objective_markers.append(marker)
    for point in L.SERVICE_POINTS:
        m._box(m,point+Vector3(0,0.12,0),Vector3(3,0.18,3),BLUE)
    m.set_meta("expanded_blocks",6)

static func _parcel(m: Node3D,c: Vector3) -> void:
    m._box(m,c+Vector3(0,0.08,0),Vector3(34,0.16,38),TILE)
    for x in [-17,17]:
        _fence(m,c+Vector3(x,0,0),38,true)
        m._box(m,c+Vector3(x,0.22,0),Vector3(0.3,0.25,38),Color(0.75,0.16,0.12))
    _fence(m,c+Vector3(0,0,-19),34,false)
    for x in [-11,11]:
        _fence(m,c+Vector3(x,0,19),12,false)

static func _fence(m: Node3D,p: Vector3,length: float,vertical: bool,parent: Node3D = null) -> void:
    var host: Node3D = m if parent == null else parent
    for h in [0.65,1.2]:
        m._box(host,p+Vector3(0,h,0),Vector3(0.13,0.12,length) if vertical else Vector3(length,0.12,0.13),WHITE)
    for n in range(int(length/3)+1):
        var d: float = -length/2+n*3
        m._box(host,p+Vector3(0,0.7,d) if vertical else p+Vector3(d,0.7,0),Vector3(0.18,1.4,0.18),WHITE,true)

static func _garden(m: Node3D,p: Vector3) -> void:
    var lawn: Node3D = m._box(m,p+Vector3(0,0.18,0),Vector3(3.6,0.12,3.6),Color(0.19,0.4,0.13))
    lawn.add_to_group("tree_grass")
    lawn.set_meta("bed_size",Vector2(3.6,3.6))
    var fence_group := Node3D.new()
    m.add_child(fence_group)
    fence_group.add_to_group("tree_fences")
    for offset in [-1.9,1.9]:
        _fence(m,p+Vector3(offset,0,0),3.8,true,fence_group)
        _fence(m,p+Vector3(0,0,offset),3.8,false,fence_group)
    _tree(m,p)
    m.add_to_group("expanded_neighborhood")

static func _tree(m: Node3D,p: Vector3) -> void:
    m._box(m,p+Vector3(0,1.2,0),Vector3(0.6,2.4,0.6),Color(0.32,0.19,0.09),true)
    m._sphere(p+Vector3(0,3.4,0),Vector3(2.6,3,2.6),Color(0.13,0.37,0.12))
    m._sphere(p+Vector3(0.7,3,0.3),Vector3(2.2,2.2,2.2),Color(0.26,0.49,0.13))

static func _headquarters(m: Node3D,c: Vector3,title: String,color: Color) -> void:
    var p := c+Vector3(0,0,-3)
    m._box(m,p+Vector3(0,4,0),Vector3(21,8,18),color,true)
    for h in [3.2,7]:
        m._box(m,p+Vector3(0,h,0),Vector3(22,0.35,19),WALL)
    m._box(m,p+Vector3(0,8.2,0),Vector3(22,0.4,19),WALL)
    for x in [-10.7,10.7]:
        m._box(m,p+Vector3(x,8.7,0),Vector3(0.3,0.8,19),WALL)
    for z in [-9.3,9.3]:
        m._box(m,p+Vector3(0,8.7,z),Vector3(21,0.8,0.3),WALL)
    for x in [-8,-4,4,8]:
        for y in [1.8,5.2]:
            m._box(m,p+Vector3(x,y,9.08),Vector3(2.2,2,0.16),Color(0.98,0.58,0.09))
            m._box(m,p+Vector3(x,y,9.19),Vector3(0.12,2.2,0.1),BLUE)
    m._box(m,p+Vector3(0,1.8,9.2),Vector3(2.8,3.6,0.4),Color(0.04,0.22,0.3))
    m._box(m,p+Vector3(0,3.7,10),Vector3(7,0.4,3),BLUE)
    m._sign(title,p+Vector3(0,4.3,9.4),0.018)
    for x in [-8,8]:
        m._box(m,p+Vector3(x,8.8,0),Vector3(3,0.9,3),WALL)

static func _hangar(m: Node3D,c: Vector3,kind: int) -> void:
    var p := c+Vector3(0,0,-5 if kind != 2 else -10)
    var depth := 18.0 if kind != 2 else 12.0
    m._box(m,p+Vector3(0,3,0),Vector3(24,6,depth),WALL,true)
    for side in [-1,1]:
        var roof: Node3D = m._box(m,p+Vector3(side*6,7,0),Vector3(12.7,0.3,depth+1),BLUE if kind == 1 else Color(0.29,0.34,0.42))
        roof.rotation.z = side*-0.17
    for side in [-1,1]:
        for z in range(-6,7,3):
            m._box(m,p+Vector3(side*12.1,4.2,z),Vector3(0.14,1.5,1.8),GOLD)
        m._box(m,p+Vector3(side*12.15,0.5,0),Vector3(0.2,0.8,depth),BLUE)
    for x in [-8,0,8]:
        m._box(m,p+Vector3(x,2,depth/2+0.08),Vector3(5,4,0.18),Color(0.11,0.16,0.19))
        for dx in [-2.6,2.6]:
            m._box(m,p+Vector3(x+dx,2,depth/2+0.22),Vector3(0.16,4.3,0.16),GOLD)
    var gable := SurfaceTool.new()
    gable.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in [-depth/2,depth/2]:
        for v in [Vector3(-12,6,z),Vector3(0,8.05,z),Vector3(12,6,z)]:
            gable.add_vertex(v)
    gable.generate_normals()
    var end := MeshInstance3D.new()
    end.mesh = gable.commit()
    var mat: StandardMaterial3D = m._material(WALL).duplicate()
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    end.material_override = mat
    m.add_child(end)
    end.position = p
    for x in range(-11,12,2):
        m._box(m,p+Vector3(x,7.6-absf(x)*0.17,0),Vector3(0.06,0.07,depth+1),WALL)
    m._sign(L.BLOCK_NAMES[kind],p+Vector3(0,5.4,depth/2+0.3),0.016 if kind == 5 else 0.023)
    if kind == 3:
        for x in [-10,-8]:
            m._box(m,c+Vector3(x,1.5,-16),Vector3(1.5,3,1.5),WHITE,true)

static func _pad(m: Node3D,p: Vector3,radius: float) -> void:
    m._box(m,p,Vector3(radius*2,0.06,radius*2),ROAD)
    for side in [-1,1]:
        m._box(m,p+Vector3(side*radius*0.5,0.06,0),Vector3(0.5,0.03,radius*1.2),GOLD)
        m._box(m,p+Vector3(side*radius,0.05,0),Vector3(0.22,0.03,radius*2),GOLD)
        m._box(m,p+Vector3(0,0.05,side*radius),Vector3(radius*2,0.03,0.22),GOLD)
    m._box(m,p+Vector3(0,0.06,0),Vector3(radius,0.03,0.5),GOLD)

static func _lamp(m: Node3D,p: Vector3) -> void:
    m._box(m,p+Vector3(0,2.5,0),Vector3(0.16,5,0.16),BLUE,true)
    var bulb: Node3D = m._box(m,p+Vector3(0,4.9,0),Vector3(0.9,0.6,0.9),GOLD)
    bulb.get_child(0).material_override = m._material(GOLD,true)
    m._box(m,p+Vector3(0,5.3,0),Vector3(1.2,0.18,1.2),BLUE)
    if p.x != 15 and p.x != -27:
        return
    if p.x == -27 and p.z > 0:
        return
    var light := OmniLight3D.new()
    light.light_color = GOLD
    light.light_energy = 1.6
    light.omni_range = 8
    light.shadow_enabled = false
    m.add_child(light)
    light.position = p+Vector3(0,4.6,0)

static func _tower(m: Node3D,p: Vector3) -> void:
    for x in [-1.3,1.3]:
        for z in [-1.3,1.3]:
            m._box(m,p+Vector3(x,4,z),Vector3(0.35,8,0.35),BLUE,true)
    m._box(m,p+Vector3(0,7,0),Vector3(4,0.5,4),GOLD)
    m._box(m,p+Vector3(0,8.1,0),Vector3(3.4,1.8,3.4),WALL)
    m._box(m,p+Vector3(0,9.2,0),Vector3(4.1,0.35,4.1),BLUE)
    for z in [-1.76,1.76]:
        m._box(m,p+Vector3(0,8.2,z),Vector3(2.5,0.8,0.12),GOLD)

static func _radio(m: Node3D,p: Vector3) -> void:
    for x in [-1,1]:
        m._box(m,p+Vector3(x,7,0),Vector3(0.25,14,0.25),Color(0.8,0.13,0.13))
    for y in range(2,15,2):
        m._box(m,p+Vector3(0,y,0),Vector3(2.5,0.15,0.2),WHITE)
    m._sphere(p+Vector3(0,14.3,0),Vector3(0.6,0.6,0.6),Color(1,0.1,0.1))
    m._sphere(p+Vector3(4,9,0),Vector3(3,3,0.6),WHITE)

static func _container(m: Node3D,p: Vector3) -> void:
    m._box(m,p+Vector3(0,1.4,0),Vector3(5,2.8,3),Color(0.2,0.36,0.19),true)
    for x in range(-2,3):
        m._box(m,p+Vector3(x,1.4,1.55),Vector3(0.09,2.6,0.08),GOLD)

static func _truck(m: Node3D,p: Vector3) -> void:
    m._box(m,p+Vector3(0,1.2,0),Vector3(4.6,1.8,2.2),Color(0.26,0.33,0.2),true)
    m._box(m,p+Vector3(-1.4,2.2,0),Vector3(1.8,1,2.1),BLUE)
    for x in [-1.5,1.5]:
        for z in [-1.1,1.1]:
            m._sphere(p+Vector3(x,0.55,z),Vector3(0.85,0.85,0.4),Color(0.07,0.08,0.1))

static func _helicopter(m: Node3D,p: Vector3) -> void:
    m._sphere(p+Vector3(0,1.4,0),Vector3(2.5,2.2,4.7),Color(0.26,0.31,0.2))
    m._box(m,p+Vector3(0,1.5,3.2),Vector3(0.45,0.5,4.5),BLUE)
    m._box(m,p+Vector3(0,3,0),Vector3(9,0.12,0.3),Color(0.08,0.09,0.11))
    for x in [-1,1]:
        m._box(m,p+Vector3(x,0.35,0),Vector3(0.14,0.2,4),WALL)

static func _coast(m: Node3D) -> void:
    var water: Node3D = m._box(m,Vector3(0,-9,0),Vector3(600,0.4,600),Color(0.025,0.22,0.35))
    var ocean := ShaderMaterial.new()
    ocean.shader = preload("res://scripts/coastal_water.gdshader")
    water.get_child(0).material_override = ocean
    for i in range(44):
        var a: float = i*TAU/44
        var edge := Vector2(sin(a),cos(a)) / maxf(absf(sin(a)),absf(cos(a)))
        var p := Vector3(edge.x*80,-5,edge.y*71)
        var cliff: Node3D = m._box(m,p,Vector3(12+sin(i*3)*3,12,11),Color(0.35+0.04*sin(i),0.28,0.25))
        cliff.rotation = Vector3(0.12*sin(i*7),i*0.8,0.15*cos(i*4))
        m._sphere(p+Vector3(0,-3,3),Vector3(12,0.5,10),Color(0.35,0.69,0.73))
    for x in [-55,-4,49]:
        m._box(m,Vector3(x,-4,77),Vector3(3,9,0.35),Color(0.23,0.76,0.87))
        for dx in [-1,0,1]:
            m._box(m,Vector3(x+dx,-4.5,77.3),Vector3(0.2,8,0.1),WHITE)
    var road := [Vector3(68,1,-62),Vector3(78,1,-77),Vector3(91,1,-91),Vector3(92,1,-108),Vector3(83,1,-125),Vector3(88,1,-145)]
    for i in range(road.size()-1):
        var from: Vector3 = road[i]
        var to: Vector3 = road[i+1]
        var segment: Node3D = m._box(m,(from+to)*0.5,Vector3(7,0.2,from.distance_to(to)+2),ROAD)
        segment.rotation.y = atan2(to.x-from.x,to.z-from.z)
        m._box(m,(from+to)*0.5-Vector3(0,5,0),Vector3(17,10,from.distance_to(to)+8),Color(0.32,0.3,0.23))
        for side in [-1,1]:
            m._box(segment,Vector3(side*0.2,0.13,0),Vector3(0.1,0.02,from.distance_to(to)),GOLD)
    for i in range(18):
        var x: float = -82+i*9
        m._sphere(Vector3(x,1,-72),Vector3(17,15+5*sin(i),18),Color(0.35,0.29,0.25))
        _tree(m,Vector3(x,7,-72))
        _tree(m,Vector3(x+3,5,-67))
        for n in range(3):
            _tree(m,Vector3(x+n*2.4-2,6+sin(i*4+n)*2,-76-n*3))
