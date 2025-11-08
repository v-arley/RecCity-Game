extends Node
class_name DeliveryController

# ======================================================
# === REFERENCIAS ======================================
# ======================================================

@export var target_vehicle: VehicleBody3D
@export var spawner: SpawnerController
@export var containers: Array[Node3D] = []
@export var container_type_names: Array[String] = ["Plastico", "Vidrio", "Papel", "Organico", "Metal"]

# --- UI ---
@export var hud: HUDController
@export var game_controller: GameController  # Para refrescar todos los labels del Game Over

# --- Configuración de nodos hijos ---
@export var area_node_name := "DeliveryArea"
@export var highlight_node_name := "Highlight"

# ======================================================
# === VARIABLES INTERNAS ===============================
# ======================================================

var current_container: Node3D = null
var current_container_type: String = ""
var correct_deliveries: int = 0
var wrong_deliveries: int = 0

# ======================================================
# === CICLO DE VIDA ====================================
# ======================================================

func _ready():
	if not target_vehicle:
		push_error("[DeliveryController] Falta 'target_vehicle'")
	if not spawner:
		push_error("[DeliveryController] Falta 'spawner'")
	if not hud:
		push_warning("[DeliveryController] Falta 'hud' — la UI no se actualizará")

	for i in range(containers.size()):
		var cont := containers[i]
		if not cont or not is_instance_valid(cont):
			continue

		var type_name: String = container_type_names[i] if i < container_type_names.size() else "Desconocido"
		cont.set_meta("container_type", type_name)

		var area := cont.get_node_or_null(area_node_name)
		if area and area is Area3D:
			area.body_entered.connect(_on_container_area_entered.bind(cont))
			area.body_exited.connect(_on_container_area_exited.bind(cont))

		_set_container_highlight(cont, false)

# ======================================================
# === DETECCIÓN DE COLISIÓN CON CONTENEDORES ===========
# ======================================================

func _on_container_area_entered(body: Node, cont: Node3D):
	if body == target_vehicle:
		current_container = cont
		current_container_type = cont.get_meta("container_type", "Desconocido")
		_set_container_highlight(cont, true)
		print("[Entrega] Entró al contenedor:", current_container_type)

func _on_container_area_exited(body: Node, cont: Node3D):
	if body == target_vehicle and current_container == cont:
		_set_container_highlight(cont, false)
		current_container = null
		current_container_type = ""
		print("[Entrega] Salió del contenedor")

func _set_container_highlight(cont: Node3D, on: bool):
	var hl := cont.get_node_or_null(highlight_node_name)
	if hl and hl is Node3D:
		hl.visible = on

# ======================================================
# === LÓGICA DE ENTREGA ================================
# ======================================================

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_deliver()

func _try_deliver():
	if not current_container:
		print("[Entrega] No estás dentro de un contenedor.")
		return
	
	if not spawner:
		print("[Entrega] Falta Spawner.")
		return

	if not spawner.has_trash():
		print("[Entrega] No llevas basura.")
		return

	var carried_type: String = spawner.get_carried_trash_type()
	spawner.clear_trash()

	var is_correct: bool = (carried_type == current_container_type)
	if is_correct:
		correct_deliveries += 1
		print("[Entrega] ✅ CORRECTA:", carried_type, "->", current_container_type)
		if hud:
			hud.add_correct(carried_type)
	else:
		wrong_deliveries += 1
		print("[Entrega] ❌ INCORRECTA:", carried_type, "->", current_container_type)
		if hud:
			hud.add_incorrect()

	# ======================================================
	# === 🔄 REFRESCAR TODOS LOS LABELS DEL GAME OVER ======
	# ======================================================
	if game_controller:
		game_controller.refresh_game_over_stats()

		# Si tienes más labels como totales o porcentaje, actualízalos aquí también
		if game_controller.has_node("lbl_total_deliveries"):
			var total := hud.total_corrects + hud.total_incorrects
			var label_total = game_controller.get_node("lbl_total_deliveries")
			label_total.text = "Entregas totales: %d" % total

		if game_controller.has_node("lbl_accuracy"):
			var total := hud.total_corrects + hud.total_incorrects
			var accuracy := 0
			if total > 0:
				accuracy = int((float(hud.total_corrects) / total) * 100)
			var label_acc = game_controller.get_node("lbl_accuracy")
			label_acc.text = "Eficiencia: %d%%" % accuracy
