extends Node

# Botones (asignados por parámetro en el Inspector)
@export var button_start: TextureButton
@export var button_exit: TextureButton
@export var button_settings: TextureButton
@export var button_menu: TextureButton
@export var button_credits: TextureButton
@export var button_continue: TextureButton
@export var button_instructions: TextureButton

@export var button_restart: TextureButton

# Labels (opcional, si las vas a usar)
@export var label_glass_count: Label
@export var label_metal_count: Label
@export var label_plastic_count: Label
@export var label_general_count: Label
@export var label_paper_count: Label
@export var label_correct_count: Label
@export var label_incorrect_count: Label

# ProgressBar
@export var progressBar_Life: ProgressBar

# CanvasLayers
@export var MenuScreen: CanvasLayer
@export var GameScreen: CanvasLayer
@export var PauseScreen: CanvasLayer
@export var GameOverScreen: CanvasLayer

func _ready():
	print("Esto es una prueba para ver si la lógica es la de este script !")
	# Conectar señales solo si los botones están asignados
	if button_start:
		button_start.pressed.connect(_on_button_start_pressed)
	if button_exit:
		button_exit.pressed.connect(_on_button_exit_pressed)
	if button_menu:
		button_menu.pressed.connect(_on_button_menu_pressed)
	if button_settings:
		button_settings.pressed.connect(_on_button_settings_pressed)
	if button_continue:
		button_continue.pressed.connect(_on_button_continue_pressed)
	if button_continue:
		button_continue.pressed.connect(_on_button_continue_pressed)

func _on_button_start_pressed():
	print("El boton start ha sido presionado")
	if MenuScreen: MenuScreen.hide()
	if GameScreen: GameScreen.show()
	if AudioManager: 
		AudioManager.play_selected()
		AudioManager.play_game_music()

func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_menu_pressed():
	if MenuScreen: MenuScreen.show()
	if GameScreen: GameScreen.hide()
	if PauseScreen: PauseScreen.hide()
	if GameOverScreen: GameOverScreen.hide()

func _on_button_settings_pressed():
	if PauseScreen: PauseScreen.show()

func _on_button_continue_pressed():
	if PauseScreen: PauseScreen.hide()
	if GameScreen: GameScreen.show()
