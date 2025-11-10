extends Node

# --- Parámetros de la cámara ---
@export var target_camera: Camera3D
@export var target_vehicle: VehicleBody3D
@export var follow_distance: float = 5.0
@export var follow_height: float = 3.0
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 3.0
@export var look_ahead_distance: float = 0.0

# Referencia al Spawner
@export var spawner_controller: Node

# Variables internas
var desired_position: Vector3
var desired_rotation: Vector3

func _ready():
	print("AudioManager existe: ", AudioManager != null)
	if not target_camera:
		push_error("target_camera no está asignado.")
		return
	
	if not target_vehicle:
		push_error("target_vehicle no está asignado.")
		return

	# Configurar cámara inicial
	update_camera_position()

	# Inicializar el spawner si está asignado
	if spawner_controller:
		spawner_controller.target_vehicle = target_vehicle

func _process(delta):
	if not target_camera or not target_vehicle:
		return

	update_camera_position()
	smooth_camera_movement(delta)

# ======================================================
# === CÁMARA DE SEGUIMIENTO ============================
# ======================================================

func update_camera_position():
	var vehicle_transform = target_vehicle.global_transform
	var vehicle_position = vehicle_transform.origin
	var vehicle_forward = -vehicle_transform.basis.z
	
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
