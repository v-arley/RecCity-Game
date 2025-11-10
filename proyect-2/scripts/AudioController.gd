extends Node

@onready var music_player = $MusicPlayer
@onready var sfx_player = $SFXPlayer
@onready var ui_sounds = $SFXPlayer
	

# Música
var menu_music: AudioStream
var game_music: AudioStream
var pickup_sound: AudioStream
var game_over_sound : AudioStream
var crash_sound : AudioStream
var selected_sound : AudioStream

func _ready():	
	
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_sounds.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cargar los archivos de audio
	menu_music = load("res://assets/sounds/menuSound.wav")
	game_music = load("res://assets/sounds/backgrounNoises.wav")
	pickup_sound = load("res://assets/sounds/trash.wav")
	game_over_sound = load("res://assets/sounds/gameOver.wav")
	crash_sound = load("res://assets/sounds/crash.wav")
	selected_sound = load("res://assets/sounds/selected.wav")
	
	
	# Conectar señal para loop automático
	music_player.finished.connect(_on_music_finished)

func _on_music_finished():
	# Reproducir de nuevo solo si es música de fondo
	if music_player.playing == false and (music_player.stream == menu_music or music_player.stream == game_music):
		music_player.play()

func play_menu_music():
	# Detener música actual primero
	music_player.stop()
	# Configurar y reproducir música del menú
	music_player.stream = menu_music
	music_player.play()

func play_game_music():
	# Detener música actual primero  
	music_player.stop()
	# Configurar y reproducir música del juego
	music_player.stream = game_music
	music_player.play()

func play_selected():
	ui_sounds.stream = selected_sound
	ui_sounds.play()
	
func play_pickup_sound():
	sfx_player.stream = pickup_sound
	sfx_player.play()
	
func play_game_over_sound():
	sfx_player.stream = game_over_sound
	sfx_player.play()
	
func play_crash_sound():
	sfx_player.stream = crash_sound
	sfx_player.play()

func stop_music():
	music_player.stop()
