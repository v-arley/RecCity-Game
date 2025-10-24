extends Node  # Ahora puedes usar Node en lugar de Node3D

# --- Parámetros de la cámara ---
@export var target_camera: Camera3D
@export var target_vehicle: VehicleBody3D
@export var position_spawn: Array[Node3D] = []
@export var objects_model: Array[PackedScene] = []

@export var follow_distance: float = 8.0
@export var follow_height: float = 5.0
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var look_ahead_distance: float = 2.0

# Variables
var desired_position: Vector3
var desired_rotation: Vector3

# Configuración del sistema de spawneo
@export var max_active_objects: int = 4
@export var auto_spawn_on_start: bool = true
@export var initial_spawn_count: int = 4

# Variables internas para trackear spawns
var spawned_objects_list: Array[Node3D] = []
var _current_colliding: Dictionary = {}

func _ready():
	if not target_camera:
		push_error("target_camera no está asignado.")
		return
	
	if not target_vehicle:
		push_error("target_vehicle no está asignado.")
		return

	# Configurar la posición inicial de la cámara
	update_camera_position()
	
	# Limpiar posiciones de spawn ocupadas al iniciar
	clear_spawn_positions_on_start()
	
	# Spawneo automático al iniciar (si está habilitado)
	if auto_spawn_on_start and not objects_model.is_empty() and not position_spawn.is_empty():
		spawn_multiple_random(initial_spawn_count)

func _process(delta: float) -> void:
	if not target_camera or not target_vehicle:
		return
	
	update_camera_position()
	smooth_camera_movement(delta)

func _physics_process(delta: float) -> void:
	# No necesitas hacer detección manual aquí, ya que usaremos Area3D
	pass

func update_camera_position():
	var vehicle_transform = target_vehicle.global_transform
	var vehicle_position = vehicle_transform.origin
	var vehicle_forward = -vehicle_transform.basis.z
	var vehicle_right = vehicle_transform.basis.x
	
	var back_offset = vehicle_forward * follow_distance
	var height_offset = Vector3.UP * follow_height
	desired_position = vehicle_position + back_offset + height_offset
	
	var look_target = vehicle_position + vehicle_forward * look_ahead_distance
	var look_direction = (look_target - desired_position).normalized()
	desired_rotation = get_rotation_to_look_at(look_direction)

func smooth_camera_movement(delta: float):
	target_camera.global_position = target_camera.global_position.lerp(desired_position, follow_speed * delta)
	
	var current_euler = target_camera.global_rotation
	var target_euler = desired_rotation
	
	current_euler.x = lerp_angle(current_euler.x, target_euler.x, rotation_speed * delta)
	current_euler.y = lerp_angle(current_euler.y, target_euler.y, rotation_speed * delta)
	current_euler.z = lerp_angle(current_euler.z, target_euler.z, rotation_speed * delta)
	
	target_camera.global_rotation = current_euler

func get_rotation_to_look_at(direction: Vector3) -> Vector3:
	var up = Vector3.UP
	var right = direction.cross(up).normalized()
	var corrected_up = right.cross(direction).normalized()
	
	var basis = Basis()
	basis.x = right
	basis.y = corrected_up
	basis.z = -direction
	
	return basis.get_euler()

func set_target_camera(new_camera: Camera3D):
	target_camera = new_camera

func set_target_vehicle(new_target: VehicleBody3D):
	target_vehicle = new_target
	if target_vehicle and target_camera:
		update_camera_position()

func set_follow_distance(distance: float):
	follow_distance = distance

func set_follow_height(height: float):
	follow_height = height

func get_camera_info() -> Dictionary:
	return {
		"camera_position": target_camera.global_position if target_camera else Vector3.ZERO,
		"camera_rotation": target_camera.global_rotation if target_camera else Vector3.ZERO,
		"target_camera": target_camera.name if target_camera else "None",
		"target_vehicle": target_vehicle.name if target_vehicle else "None",
		"follow_distance": follow_distance,
		"follow_height": follow_height
	}

# === SISTEMA DE SPAWNEO BÁSICO ===

func spawn_random_object() -> Node3D:
	if objects_model.is_empty() or position_spawn.is_empty():
		return null
	
	if spawned_objects_list.size() >= max_active_objects:
		return null
	
	var free_position = get_free_spawn_position()
	if free_position == -1:
		return null
	
	var random_model = randi() % objects_model.size()
	return spawn_object_at_position(random_model, free_position)

func spawn_object_at_position(model_index: int, position_index: int) -> Node3D:
	if model_index >= objects_model.size() or position_index >= position_spawn.size():
		return null
	
	if is_position_occupied(position_index):
		return null
	
	if spawned_objects_list.size() >= max_active_objects:
		return null
	
	var scene = objects_model[model_index]
	var spawn_pos = position_spawn[position_index]
	
	if not scene or not spawn_pos:
		return null
	
	var spawned_object = scene.instantiate()
	spawned_object.position = Vector3.ZERO
	spawned_object.rotation = Vector3.ZERO
	spawned_object.visible = true

	if spawned_object is Node:
		spawned_object.add_to_group("objects_model")

	# Conectar señales de Area3D si tiene
	if spawned_object is Node3D:
		for child in spawned_object.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_area_body_entered.bind(spawned_object))
				child.body_exited.connect(_on_area_body_exited.bind(spawned_object))

	spawn_pos.add_child(spawned_object)
	spawned_objects_list.append(spawned_object)
	
	return spawned_object

func spawn_multiple_random(count: int) -> int:
	var spawned_count = 0
	
	for i in range(count):
		var obj = spawn_random_object()
		if obj:
			spawned_count += 1
		else:
			break
	
	return spawned_count

func is_position_occupied(position_index: int) -> bool:
	if position_index >= position_spawn.size():
		return true
	
	var spawn_node = position_spawn[position_index]
	if not spawn_node or not is_instance_valid(spawn_node):
		return true

	return spawn_node.get_child_count() > 0

func get_free_spawn_position() -> int:
	var free_positions: Array[int] = []
	
	for i in range(position_spawn.size()):
		if not is_position_occupied(i):
			free_positions.append(i)
	
	if free_positions.is_empty():
		return -1
	
	return free_positions[randi() % free_positions.size()]

# --- DETECCIÓN DE COLISIONES CON AREA3D ---

func _on_area_body_entered(body, spawned_obj: Node3D):
	if body == target_vehicle:
		var iid = spawned_obj.get_instance_id()
		_current_colliding[iid] = spawned_obj
		print("[mainController] Vehículo colisionó con: %s (instance_id=%d)" % [spawned_obj.name, iid])

func _on_area_body_exited(body, spawned_obj: Node3D):
	if body == target_vehicle:
		var iid = spawned_obj.get_instance_id()
		_current_colliding.erase(iid)

# Contar objetos activos spawneados
func get_active_objects_count() -> int:
	spawned_objects_list = spawned_objects_list.filter(func(obj): return is_instance_valid(obj))
	return spawned_objects_list.size()

# Limpiar todos los objetos spawneados
func clear_all_spawned_objects():
	for obj in spawned_objects_list:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects_list.clear()

# Función para limpiar posiciones ocupadas al iniciar
func clear_spawn_positions_on_start():
	for spawn_node in position_spawn:
		if is_instance_valid(spawn_node):
			for child in spawn_node.get_children():
				child.queue_free()

# === FUNCIONES DE TESTING Y DEBUG ===

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				spawn_random_object()
			KEY_2:
				spawn_multiple_random(3)
			KEY_3:
				clear_all_spawned_objects()	
