extends VehicleBody3D
class_name VehicleController

# --- Wheels ---
@export var front_left_wheel: VehicleWheel3D
@export var front_right_wheel: VehicleWheel3D
@export var rear_left_wheel: VehicleWheel3D
@export var rear_right_wheel: VehicleWheel3D

# --- Adjustable parameters ---
@export var engine_force_strength: float = 1200.0
@export var brake_force_strength: float = 60.0
@export var steering_angle_max: float = 0.4

# --- Key bindings ---
@export var key_forward: Key = Key.KEY_W
@export var key_backward: Key = Key.KEY_S
@export var key_left: Key = Key.KEY_A
@export var key_right: Key = Key.KEY_D
@export var key_brake: Key = Key.KEY_SPACE

# --- Bumper (Área de choque) ---
@export var bumper_area: Area3D  # arrastra el Area3D del vehículo aquí en el editor

# --- Sistema de vida ---
signal vehicle_damaged(new_health: float)
signal vehicle_destroyed

@export var max_health: float = 100.0
@export var damage_per_collision: float = 20.0
@export var collision_cooldown: float = 0.5   # para no descontar varias veces por el mismo toque

var health: float = 100.0
var can_drive: bool = true
var _cooldown_left: float = 0.0

func _ready():
	center_of_mass = Vector3(0, -0.5, 0)
	health = max_health
	
	# Conectar señales del bumper
	if bumper_area:
		bumper_area.body_entered.connect(_on_bumper_body_entered)
	else:
		push_warning("[Vehicle] 'bumper_area' no asignado; no habrá daño por choque.")

func _physics_process(delta: float) -> void:
	# cooldown de daño
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

	if not can_drive:
		engine_force = 0
		return

	if not front_left_wheel or not front_right_wheel:
		return

	var accel := 0.0
	var steer := 0.0
	var brake_force := 0.0

	# Aceleración y reversa
	if Input.is_key_pressed(key_forward):
		accel = 1.0
	elif Input.is_key_pressed(key_backward):
		accel = -1.0

	# Freno
	if Input.is_key_pressed(key_brake):
		brake_force = brake_force_strength

	# Dirección
	if Input.is_key_pressed(key_left):
		steer = 1.0
	elif Input.is_key_pressed(key_right):
		steer = -1.0

	# Aplicar fuerza del motor
	engine_force = accel * engine_force_strength

	# Aplicar dirección (solo ruedas delanteras)
	var steer_value := steer * steering_angle_max
	front_left_wheel.steering = steer_value
	front_right_wheel.steering = steer_value

	# Aplicar freno a todas las ruedas
	for wheel in [front_left_wheel, front_right_wheel, rear_left_wheel, rear_right_wheel]:
		if wheel:
			wheel.brake = brake_force

# =======================
#  Choque / Daño
# =======================

func _on_bumper_body_entered(body: Node):
	# Puedes filtrar lo que NO debe hacer daño (ej.: basura recolectable)
	# if body.is_in_group("collectibles"): return
	# print("[Vehicle] body_entered:", body)
	if body == self:
		return
		
	if _cooldown_left > 0.0:
		return  # evita múltiples daños por el mismo contacto breve
	
	_take_damage(damage_per_collision)
	_cooldown_left = collision_cooldown

func _take_damage(amount: float):
	if health <= 0:
		return
	
	health = max(0.0, health - amount)
	print("[Vehicle] Daño:", amount, " | Vida:", health)
	emit_signal("vehicle_damaged", health)
	if AudioManager:
		AudioManager.play_crash_sound()

	if health <= 0.0:
		can_drive = false
		print("[Vehicle] Vehículo destruido.")
		emit_signal("vehicle_destroyed")
