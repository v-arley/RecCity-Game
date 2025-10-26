extends Node
class_name GameController

# ======================================================
# === REFERENCIAS ======================================
# ======================================================

@export var vehicle: VehicleController     # <<-- Tipo actualizado
@export var menu_screen: CanvasLayer
@export var game_screen: CanvasLayer
@export var game_over_screen: CanvasLayer
@export var lbl_timer: Label
@export var btn_start: Button
@export var prg_health: ProgressBar        # <<-- NUEVO: barra de vida

# ======================================================
# === VARIABLES DE TIEMPO ==============================
# ======================================================

@export var start_time_minutes: int = 10
var remaining_time: float = 0.0
var game_running: bool = false

# ======================================================
# === CICLO DE VIDA ====================================
# ======================================================

func _ready():
	_show_menu_screen()
	_disable_vehicle_controls()
	
	if btn_start:
		btn_start.pressed.connect(_on_btn_start_pressed)
	
	if vehicle:
		vehicle.vehicle_damaged.connect(_on_vehicle_damaged)
		vehicle.vehicle_destroyed.connect(_on_vehicle_destroyed)
	
	if prg_health:
		prg_health.value = 100

func _process(delta: float):
	if game_running:
		remaining_time -= delta
		if remaining_time <= 0:
			remaining_time = 0
			_end_game()
		_update_timer_label()

# ======================================================
# === EVENTOS DE JUEGO =================================
# ======================================================

func _on_btn_start_pressed():
	_start_game()

func _start_game():
	game_running = true
	remaining_time = float(start_time_minutes * 60)
	
	menu_screen.visible = false
	game_over_screen.visible = false
	game_screen.visible = true
	
	if prg_health:
		prg_health.value = 100
	
	_enable_vehicle_controls()
	_update_timer_label()

func _end_game():
	print("[Game] Fin del juego.")
	game_running = false
	_disable_vehicle_controls()
	game_screen.visible = false
	game_over_screen.visible = true

# ======================================================
# === MANEJO DE VIDA ===================================
# ======================================================

func _on_vehicle_damaged(new_health: float):
	if prg_health:
		prg_health.value = new_health

func _on_vehicle_destroyed():
	print("[Game] Vehículo destruido. Fin del juego.")
	_end_game()

# ======================================================
# === VEHÍCULO: ACTIVAR/DESACTIVAR =====================
# ======================================================

func _enable_vehicle_controls():
	if vehicle:
		vehicle.can_drive = true
		vehicle.set_physics_process(true)

func _disable_vehicle_controls():
	if vehicle:
		vehicle.can_drive = false
		vehicle.set_physics_process(false)

# ======================================================
# === PANTALLAS ========================================
# ======================================================

func _show_menu_screen():
	menu_screen.visible = true
	game_screen.visible = false
	game_over_screen.visible = false
	_update_timer_label()

# ======================================================
# === TIMER UI =========================================
# ======================================================

func _update_timer_label():
	if lbl_timer:
		var minutes = int(remaining_time) / 60
		var seconds = int(remaining_time) % 60
		lbl_timer.text = "%02d:%02d" % [minutes, seconds]
