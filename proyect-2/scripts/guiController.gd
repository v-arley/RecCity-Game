extends Node

# Referencias a pantallas
@onready var menu_screen = $MenuScreen
@onready var game_screen = $GameScreen
@onready var credits_screen = $CreditsScreen

# Referencia a botones
@onready var start_button = $MenuScreen/BnStart

# Referencia a progress bar
@onready var life_value = $GameScreen/VBoxContainer1/LifeProgressBar

# Referencias a labels
@onready var lbl_time = $GameScreen/VBoxContainer2/Time
@onready var lbl_Alerts = $GameScreen/VBoxContainer3/LblAlerts

# Referencias a labels
@onready var lbl_PaperValue = $GameScreen/HBoxContainer1/VBoxContainer1/Panel/LblCountValuePaper
@onready var lbl_GlassValue = $GameScreen/HBoxContainer1/VBoxContainer2/Panel/LblCountValueGlass
@onready var lbl_MetalValue = $GameScreen/HBoxContainer1/VBoxContainer3/Panel/LblCountValueMetal
@onready var lbl_PlasticValue = $GameScreen/HBoxContainer1/VBoxContainer4/Panel/LblCountValuePlastic
@onready var lbl_GeneralValue = $GameScreen/HBoxContainer1/VBoxContainer5/Panel/LblCountValueGeneral

# Señales
signal show_menu_requested
signal show_game_requested
signal show_credits_requested

# Variables de juego
var game_time: float = 0.0
var is_game_running: bool = false

# []
func _ready():
	show_menu_requested.connect(show_menu)
	show_game_requested.connect(show_game)
	show_credits_requested.connect(show_credits)
	
	show_menu()
	lbl_Alerts.hide()
	start_button.pressed.connect(_on_bnStart_pressed)

func _process(delta: float):
	if not is_game_running:
		return
	
	game_time += delta
	_update_time_label()

func _update_time_label():
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	lbl_time.text = "%02d:%02d" % [minutes, seconds]

# --- Métodos públicos ---
func show_menu():
	menu_screen.visible = true
	game_screen.visible = false
	credits_screen.visible = false
	is_game_running = false

func show_game():
	menu_screen.visible = false
	game_screen.visible = true
	credits_screen.visible = false
	
	game_time = 0.0
	is_game_running = true
	_update_time_label()

func show_credits():
	menu_screen.visible = false
	game_screen.visible = false
	credits_screen.visible = true
	is_game_running = false

# --- Callbacks ---
func _on_bnStart_pressed():
	show_game()

# funciones para acceder deste el main y modificar los labels
func show_alert(message: String, duration: float = 2.0):
	lbl_Alerts.text = message
	lbl_Alerts.show()
	
	await get_tree().create_timer(duration).timeout
	lbl_Alerts.text = ""
	lbl_Alerts.hide()

# --- Funciones para incrementar contadores ---
func updateValuePaper():
	_increment_label(lbl_PaperValue)

func updateValueGlass():
	_increment_label(lbl_GlassValue)

func updateValueMetal():
	_increment_label(lbl_MetalValue)

func updateValuePlastic():
	_increment_label(lbl_PlasticValue)

func updateValueGeneral():
	_increment_label(lbl_GeneralValue)

# --- Función auxiliar privada (reutilizable) ---
func _increment_label(label: Label):
	var current = 0
	if label.text.is_valid_int():
		current = int(label.text)
	label.text = str(current + 1)
	
# Reduce la barra de vida en 'amount' unidades (0-100)
func reduce_life(amount: float):
	if not is_instance_valid(life_value):
		return
	
	# Asegurar que el valor no baje de 0
	var new_value = max(0, life_value.value - amount)
	life_value.value = new_value
	
	# Opcional: mostrar alerta si la vida es baja
	if new_value <= 20:
		show_alert("¡Vida baja!", 1.5)
	
	# Opcional: si llega a 0 ?
	# if new_value <= 0:
