extends Node3D

# ===================== Vehículos =====================
@export var vehicle_scene: PackedScene
@export var vehicle_scenes: Array[PackedScene] = []

# ===================== Rutas =====================
@export var paths: Array[Path3D] = []

# ==== Parámetros por ruta (mismo orden que paths) ====
@export var base_speed_forward_per_path: Array[float] = []
@export var speed_var_forward_per_path: Array[float] = []
@export var base_speed_reverse_per_path: Array[float] = []
@export var speed_var_reverse_per_path: Array[float] = []
@export var spacing_forward_per_path: Array[float] = []
@export var spacing_reverse_per_path: Array[float] = []
@export var bidirectional_per_path: Array[bool] = []
@export var num_forward_per_path: Array[int] = []
@export var num_reverse_per_path: Array[int] = []

# ===================== Defaults globales =====================
@export var num_forward: int = 4
@export var num_reverse: int = 3
@export var start_jitter_m: float = 1.0
@export var min_gap_m: float = 20.0
@export var oriented: bool = true
@export_range(-5.0, 5.0, 0.1) var lane_offset_forward: float = 0.8
@export_range(-5.0, 5.0, 0.1) var lane_offset_reverse: float = -0.8
@export var model_yaw_fix_deg_forward: float = 180.0
@export var model_yaw_fix_deg_reverse: float = 0.0
@export var default_base_speed_forward: float = 10.0
@export var default_speed_var_forward: float = 3.0
@export var default_base_speed_reverse: float = 10.0
@export var default_speed_var_reverse: float = 3.0
@export var default_spacing_forward: float = 50.0
@export var default_spacing_reverse: float = 50.0
@export var default_bidirectional: bool = true

# ===================== Cache =====================
var _path_lengths: Dictionary = {}   # Path3D -> length

func _ready() -> void:
	assert(paths.size() > 0, "Asigna al menos una ruta en 'paths'.")
	randomize()

	for p in paths:
		if p != null:
			_path_lengths[p] = p.curve.get_baked_length()

	for i in range(paths.size()):
		var path: Path3D = paths[i]
		if path == null:
			continue

		var f_base: float = _get_float_per_path(base_speed_forward_per_path, i, default_base_speed_forward)
		var f_var: float  = _get_float_per_path(speed_var_forward_per_path, i, default_speed_var_forward)
		var f_gap: float  = _get_float_per_path(spacing_forward_per_path, i, default_spacing_forward)
		var is_bidir: bool = _get_bool_per_path(bidirectional_per_path, i, default_bidirectional)
		var n_forward: int = _get_int_per_path(num_forward_per_path, i, num_forward)

		_spawn_lane(path, +1, n_forward, f_base, f_var, lane_offset_forward,
				model_yaw_fix_deg_forward, f_gap, "lane_forward_" + path.name)

		if is_bidir:
			var r_base: float = _get_float_per_path(base_speed_reverse_per_path, i, default_base_speed_reverse)
			var r_var: float  = _get_float_per_path(speed_var_reverse_per_path, i, default_speed_var_reverse)
			var r_gap: float  = _get_float_per_path(spacing_reverse_per_path, i, default_spacing_reverse)
			var n_reverse: int = _get_int_per_path(num_reverse_per_path, i, num_reverse)

			_spawn_lane(path, -1, n_reverse, r_base, r_var, lane_offset_reverse,
					model_yaw_fix_deg_reverse, r_gap, "lane_reverse_" + path.name)

func _physics_process(delta: float) -> void:
	for i in range(paths.size()):
		var path: Path3D = paths[i]
		if path == null:
			continue
		var L: float = _path_lengths.get(path, 0.0)
		if L <= 0.0:
			continue

		var is_bidir: bool = _get_bool_per_path(bidirectional_per_path, i, default_bidirectional)

		_advance_and_space("lane_forward_" + path.name, +1, delta, L)
		if is_bidir:
			_advance_and_space("lane_reverse_" + path.name, -1, delta, L)

# ===================== Spawning =====================
func _spawn_lane(path: Path3D, dir_val: int, count: int, base_speed: float, speed_var: float,
		lane_offset: float, yaw_fix_deg: float, spacing_m: float, group_name: StringName) -> void:
	var gap: float = max(1.0, spacing_m)
	var L: float = _path_lengths.get(path, 0.0)

	for i in range(count):
		var follower := PathFollow3D.new()
		follower.loop = true
		follower.rotation_mode = PathFollow3D.ROTATION_Y if oriented else PathFollow3D.ROTATION_NONE
		follower.h_offset = lane_offset
		path.add_child(follower)

		var base_pos: float = float(i) * gap + randf_range(-start_jitter_m, start_jitter_m)
		follower.progress = _wrap_m(base_pos, L)
		follower.add_to_group(group_name)

		var scene_to_use: PackedScene = _pick_vehicle_scene()
		var car: Node3D = scene_to_use.instantiate() as Node3D
		follower.add_child(car)

		# Metadatos que usaremos en movimiento
		follower.set_meta("dir", dir_val)
		follower.set_meta("speed", max(0.1, base_speed + randf_range(-speed_var, speed_var)))
		follower.set_meta("path_length", L)

		# Orientación local del modelo
		_reset_local_pose(car, yaw_fix_deg)

# ===================== Movimiento y espaciado =====================
func _advance_and_space(group_name: StringName, dir_val: int, delta: float, L: float) -> void:
	var followers: Array = get_tree().get_nodes_in_group(group_name)
	if followers.is_empty():
		return

	# Avance
	for f in followers:
		if f is PathFollow3D:
			var follower: PathFollow3D = f
			var spd: float = (follower.get_meta("speed", 8.0) as float)
			follower.progress = _wrap_m(follower.progress + spd * dir_val * delta, L)

	# Orden por progreso para aplicar separación
	followers.sort_custom(func(a, b):
		var pa: float = (a as PathFollow3D).progress
		var pb: float = (b as PathFollow3D).progress
		return pa < pb if dir_val == +1 else pa > pb
	)

	for i in range(1, followers.size()):
		var front: PathFollow3D = followers[i - 1]
		var back: PathFollow3D = followers[i]
		var dist: float = _dist_along(front.progress, back.progress, dir_val, L)
		if dist < min_gap_m:
			back.progress = _wrap_m(front.progress - dir_val * min_gap_m, L)

# ===================== Utilidades =====================
func _get_float_per_path(arr: Array, idx: int, fallback: float) -> float:
	return float(arr[idx]) if idx < arr.size() else fallback

func _get_int_per_path(arr: Array, idx: int, fallback: int) -> int:
	return int(arr[idx]) if idx < arr.size() else fallback

func _get_bool_per_path(arr: Array, idx: int, fallback: bool) -> bool:
	return bool(arr[idx]) if idx < arr.size() else fallback

func _dist_along(front_p: float, back_p: float, dir_val: int, L: float) -> float:
	var d: float = (front_p - back_p) if dir_val == +1 else (back_p - front_p)
	if d < 0.0:
		d += L
	return d

func _wrap_m(p: float, L: float) -> float:
	if L <= 0.0:
		return p
	var r: float = fmod(p, L)
	return r + L if r < 0.0 else r

func _pick_vehicle_scene() -> PackedScene:
	if vehicle_scenes.size() > 0:
		return vehicle_scenes[randi() % vehicle_scenes.size()]
	return vehicle_scene

func _reset_local_pose(car: Node3D, yaw_fix_deg: float) -> void:
	if car == null:
		return
	car.transform = Transform3D.IDENTITY
	car.rotate_y(deg_to_rad(yaw_fix_deg))
	car.position = Vector3.ZERO
