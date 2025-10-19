extends Node

# --- Parámetros de la cámara ---
@export var target_camera: Camera3D
@export var target_vehicle: VehicleBody3D
@export var position_spawn: Array[Node3D] = []
@export var objects_model: Array[PackedScene] = [] # Array de escenas para spawnear

@export var follow_distance: float = 8.0   # Distancia detrás del vehículo
@export var follow_height: float = 5.0     # Altura sobre el vehículo
@export var follow_speed: float = 5.0      # Velocidad de seguimiento de la cámara
@export var rotation_speed: float = 3.0    # Velocidad de rotación de la cámara
@export var look_ahead_distance: float = 2.0  # Distancia para mirar adelante del vehículo

# Variables
var desired_position: Vector3
var desired_rotation: Vector3

# Configuración del sistema de spawneo
@export var max_active_objects: int = 4  # Número máximo de objetos activos
@export var auto_spawn_on_start: bool = true  # Spawneo automático al iniciar
@export var initial_spawn_count: int = 1  # Cantidad de objetos a spawnear al iniciar

# Variables internas para trackear spawns
var spawned_objects_list: Array[Node3D] = []

func _ready():
	if not target_camera:
		return
	
	if not target_vehicle:
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

func update_camera_position():
	# Obtener la transformación del vehículo
	var vehicle_transform = target_vehicle.global_transform
	var vehicle_position = vehicle_transform.origin
	var vehicle_forward = -vehicle_transform.basis.z  # En Godot, -Z es adelante
	var vehicle_right = vehicle_transform.basis.x
	
	# Calcular la posición deseada detrás del vehículo con altura
	# Posición base detrás del vehículo (invertimos la dirección)
	var back_offset = vehicle_forward * follow_distance  # Cambiado: removido el signo negativo
	# Añadir altura
	var height_offset = Vector3.UP * follow_height
	# Combinar para obtener la posición deseada
	desired_position = vehicle_position + back_offset + height_offset
	
	# Calcular hacia dónde debe mirar la cámara (un poco adelante del vehículo)
	var look_target = vehicle_position + vehicle_forward * look_ahead_distance
	
	# Calcular la rotación deseada para mirar al objetivo
	var look_direction = (look_target - desired_position).normalized()
	desired_rotation = get_rotation_to_look_at(look_direction)

func smooth_camera_movement(delta: float):
	# Interpolar suavemente la posición
	target_camera.global_position = target_camera.global_position.lerp(desired_position, follow_speed * delta)
	
	# Interpolar suavemente la rotación
	var current_euler = target_camera.global_rotation
	var target_euler = desired_rotation
	
	# Interpolar cada componente de rotación
	current_euler.x = lerp_angle(current_euler.x, target_euler.x, rotation_speed * delta)
	current_euler.y = lerp_angle(current_euler.y, target_euler.y, rotation_speed * delta)
	current_euler.z = lerp_angle(current_euler.z, target_euler.z, rotation_speed * delta)
	
	target_camera.global_rotation = current_euler

func get_rotation_to_look_at(direction: Vector3) -> Vector3:
	# Calcular la rotación necesaria para mirar en la dirección especificada
	# Crear una transformada que mire hacia la dirección
	var up = Vector3.UP
	var right = direction.cross(up).normalized()
	var corrected_up = right.cross(direction).normalized()
	
	# Crear la base de rotación
	var basis = Basis()
	basis.x = right
	basis.y = corrected_up
	basis.z = -direction  # En Godot, -Z es adelante
	
	# Convertir a ángulos de Euler
	return basis.get_euler()

# Función para cambiar la cámara objetivo dinámicamente
func set_target_camera(new_camera: Camera3D):
	target_camera = new_camera

# Función para cambiar el vehículo objetivo dinámicamente
func set_target_vehicle(new_target: VehicleBody3D):
	target_vehicle = new_target
	if target_vehicle and target_camera:
		update_camera_position()

# Función para ajustar la distancia de seguimiento
func set_follow_distance(distance: float):
	follow_distance = distance

# Función para ajustar la altura de seguimiento
func set_follow_height(height: float):
	follow_height = height

# Función para obtener información de debug
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

# Spawear un objeto aleatorio en una posición libre
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

# Spawear un modelo específico en una posición específica
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
	
	spawn_pos.add_child(spawned_object)
	spawned_objects_list.append(spawned_object)
	
	return spawned_object

# Spawear múltiples objetos aleatorios
func spawn_multiple_random(count: int) -> int:
	var spawned_count = 0
	
	for i in range(count):
		var obj = spawn_random_object()
		if obj:
			spawned_count += 1
		else:
			break
	
	return spawned_count

# Verificar si una posición está ocupada
func is_position_occupied(position_index: int) -> bool:
	if position_index >= position_spawn.size():
		return true
	
	return position_spawn[position_index].get_child_count() > 0

# Obtener una posición libre aleatoria
func get_free_spawn_position() -> int:
	var free_positions: Array[int] = []
	
	for i in range(position_spawn.size()):
		if not is_position_occupied(i):
			free_positions.append(i)
	
	if free_positions.is_empty():
		return -1
	
	return free_positions[randi() % free_positions.size()]

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
		for child in spawn_node.get_children():
			child.queue_free()

# === FUNCIONES DE TESTING Y DEBUG ===

# Input para testing rápido
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				spawn_random_object()
			KEY_2:
				spawn_multiple_random(3)
			KEY_3:
				clear_all_spawned_objects()
