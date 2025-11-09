extends Node
class_name GameController

# ======================================================
# === REFERENCIAS ======================================
# ======================================================

@export var vehicle: VehicleController
@export var hud: HUDController

@export var menu_screen: CanvasLayer
@export var game_screen: CanvasLayer
@export var game_over_screen: CanvasLayer
@export var pause_screen: CanvasLayer
@export var instruction_screen: CanvasLayer

@export var lbl_timer: Label
@export var prg_health: ProgressBar
@export var btn_start: TextureButton

# Botones
@export var btn_exit1: TextureButton
@export var btn_exit2: TextureButton
@export var btn_settings: TextureButton
@export var btn_continue: TextureButton
@export var btn_restart1: TextureButton
@export var btn_restart2: TextureButton
@export var btn_credits: TextureButton
@export var btn_instructions1: TextureButton
@export var btn_instructions2: TextureButton
@export var btn_exitInstructions: TextureButton

# Labels de Game Over
@export var lbl_paper_count: Label
@export var lbl_glass_count: Label
@export var lbl_metal_count: Label
@export var lbl_plastic_count: Label
@export var lbl_general_count: Label
@export var lbl_corrects_final: Label
@export var lbl_incorrects_final: Label

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
	
	if btn_start:    btn_start.pressed.connect(_on_btn_start_pressed)
	if btn_exit1:    btn_exit1.pressed.connect(_on_btn_exit_pressed)
	if btn_exit2:    btn_exit2.pressed.connect(_on_btn_exit_pressed)
	if btn_settings: btn_settings.pressed.connect(_on_btn_settings_pressed)
	if btn_continue: btn_continue.pressed.connect(_on_btn_continue_pressed)
	if btn_restart1: btn_restart1.pressed.connect(_on_btn_restart_pressed)
	if btn_restart2: btn_restart2.pressed.connect(_on_btn_restart_pressed)
	if btn_credits: btn_credits.pressed.connect(_on_btn_credits_pressed)
	if btn_instructions1: btn_instructions1.pressed.connect(_on_btn_instructions_pressed)
	if btn_instructions2: btn_instructions2.pressed.connect(_on_btn_instructions_pressed)
	if btn_exitInstructions: btn_exitInstructions.pressed.connect(_on_btn_exit_instructions_pressed)
	

	if vehicle:
		vehicle.vehicle_damaged.connect(_on_vehicle_damaged)
		vehicle.vehicle_destroyed.connect(_on_vehicle_destroyed)
	
	if prg_health:
		prg_health.value = 100


func _process(delta: float):
	if game_running and not get_tree().paused:
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

func _on_btn_exit_pressed():
	get_tree().quit()

func _on_btn_settings_pressed():
	print("[Game] Juego en pausa.")
	get_tree().paused = true
	pause_screen.visible = true
	menu_screen.visible = false
	game_over_screen.visible = false
	game_screen.visible = false
	_disable_vehicle_controls()

func _on_btn_continue_pressed():
	print("[Game] Continuando partida.")
	get_tree().paused = false
	pause_screen.visible = false
	menu_screen.visible = false
	game_over_screen.visible = false
	game_screen.visible = true
	_enable_vehicle_controls()

func _on_btn_restart_pressed():
	restart_game()
	
func _on_btn_credits_pressed():
	print("esto es una prueba de que se presionaron los creditos")
	
func _on_btn_instructions_pressed ():
	print("Esto es una prueba de que se presiono el boton de instrucciones")
	if game_running: 
		pause_screen.visible = false
	else:
		menu_screen.visible = false
	instruction_screen.visible = true
	
func _on_btn_exit_instructions_pressed():
	instruction_screen.visible = false
	if game_running:
		pause_screen.visible = true
	else:
		menu_screen.visible = true
	

# ======================================================
# === FUNCIONALIDAD PRINCIPAL ==========================
# ======================================================

func _start_game():
	get_tree().paused = false
	game_running = true
	remaining_time = float(start_time_minutes * 60)
	
	pause_screen.visible = false
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
	
	refresh_game_over_stats()  # Actualiza los valores finales antes de pausar
	
	await get_tree().process_frame
	get_tree().paused = true

# ======================================================
# === REFRESCAR ESTADÍSTICAS DEL GAME OVER =============
# ======================================================

func refresh_game_over_stats():
	if not hud:
		return
	lbl_paper_count.text = str(hud.counts["Paper"])
	lbl_glass_count.text = str(hud.counts["Glass"])
	lbl_metal_count.text = str(hud.counts["Metal"])
	lbl_plastic_count.text = str(hud.counts["Plastic"])
	lbl_general_count.text = str(hud.counts["General"])
	lbl_corrects_final.text = "Corrects: %d" % hud.total_corrects
	lbl_incorrects_final.text = "Incorrects: %d" % hud.total_incorrects

# ======================================================
# === REINICIO GLOBAL DEL JUEGO ========================
# ======================================================

func restart_game():
	print("[Game] Reiniciando partida...")
	get_tree().paused = false
	get_tree().reload_current_scene()

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
	get_tree().paused = false
	menu_screen.visible = true
	game_screen.visible = false
	game_over_screen.visible = false
	pause_screen.visible = false
	_update_timer_label()

# ======================================================
# === TIMER UI =========================================
# ======================================================

func _update_timer_label():
	if lbl_timer:
		var minutes = int(remaining_time) / 60
		var seconds = int(remaining_time) % 60
		lbl_timer.text = "%02d:%02d" % [minutes, seconds]
