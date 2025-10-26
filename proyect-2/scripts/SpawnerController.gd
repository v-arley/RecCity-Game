extends Node
class_name SpawnerController  # <<--- importante para poder tiparlo desde otros scripts

# ======================================================
# === CONFIGURACIÓN PRINCIPAL ==========================
# ======================================================

@export var target_vehicle: VehicleBody3D
@export var position_spawn: Array[Node3D] = []
@export var objects_model: Array[PackedScene] = []
@export var trash_type_names: Array[String] = ["Plastico", "Vidrio", "Papel", "Organico", "Metal"]
@export var max_active_objects: int = 10
@export var auto_spawn_on_start: bool = true
@export var initial_spawn_count: int = 10

# ======================================================
# === VARIABLES INTERNAS ===============================
# ======================================================

var spawned_objects_list: Array[Node3D] = []
var _current_colliding: Dictionary = {}

# --- Variables de recolección ---
var carrying_trash: bool = false
var carried_trash_type: String = ""  # Ej: "Plastico", "Vidrio", etc.

# ======================================================
# === CICLO DE VIDA ====================================
# ======================================================

func _ready():
	clear_spawn_positions_on_start()
	
	if auto_spawn_on_start and not objects_model.is_empty() and not position_spawn.is_empty():
		spawn_multiple_random(initial_spawn_count)

# ======================================================
# === FUNCIONES DE SPAWNEO ==============================
# ======================================================

func spawn_random_object() -> Node3D:
	if objects_model.is_empty() or position_spawn.is_empty():
		return null
	
	if spawned_objects_list.size() >= max_active_objects:
		return null
	
	var free_position := get_free_spawn_position()
	if free_position == -1:
		return null
	
	var random_model := randi() % objects_model.size()
	return spawn_object_at_position(random_model, free_position)

func spawn_object_at_position(model_index: int, position_index: int) -> Node3D:
	if model_index >= objects_model.size() or position_index >= position_spawn.size():
		return null
	
	if is_position_occupied(position_index):
		return null
	
	if spawned_objects_list.size() >= max_active_objects:
		return null
	
	var scene: PackedScene = objects_model[model_index]
	var spawn_pos: Node3D = position_spawn[position_index]
	
	if not scene or not spawn_pos:
		return null
	
	var spawned_object := scene.instantiate()
	spawned_object.position = Vector3.ZERO
	spawned_object.rotation = Vector3.ZERO
	spawned_object.visible = true

	# --- Guardar tipo de basura según índice/orden ---
	var type_name: String = trash_type_names[model_index] if model_index < trash_type_names.size() else "Desconocida"
	spawned_object.set_meta("trash_type", type_name)

	if spawned_object is Node:
		spawned_object.add_to_group("objects_model")

	# Conectar señales de detección si tiene Area3D
	if spawned_object is Node3D:
		for child in spawned_object.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_area_body_entered.bind(spawned_object))
				child.body_exited.connect(_on_area_body_exited.bind(spawned_object))

	spawn_pos.add_child(spawned_object)
	spawned_objects_list.append(spawned_object)
	
	return spawned_object

func spawn_multiple_random(count: int) -> int:
	var spawned_count := 0
	for i in range(count):
		var obj := spawn_random_object()
		if obj:
			spawned_count += 1
		else:
			break
	return spawned_count

# ======================================================
# === UTILIDADES =======================================
# ======================================================

func is_position_occupied(position_index: int) -> bool:
	if position_index >= position_spawn.size():
		return true
	
	var spawn_node := position_spawn[position_index]
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

func get_active_objects_count() -> int:
	spawned_objects_list = spawned_objects_list.filter(func(obj): return is_instance_valid(obj))
	return spawned_objects_list.size()

func clear_all_spawned_objects():
	for obj in spawned_objects_list:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects_list.clear()

func clear_spawn_positions_on_start():
	for spawn_node in position_spawn:
		if is_instance_valid(spawn_node):
			for child in spawn_node.get_children():
				child.queue_free()

# ======================================================
# === COLISIONES Y RECOLECCIÓN =========================
# ======================================================

func _on_area_body_entered(body, spawned_obj: Node3D):
	if body == target_vehicle:
		if not carrying_trash:  # Solo recoge si está libre
			var iid := spawned_obj.get_instance_id()
			var trash_type: String = spawned_obj.get_meta("trash_type", "Desconocida")
			
			# Guardar datos de la basura recogida
			carrying_trash = true
			carried_trash_type = trash_type

			# Eliminar la basura del mundo
			spawned_obj.queue_free()
			_current_colliding.erase(iid)
			spawned_objects_list.erase(spawned_obj)
			
			print("[Recolección] Camión recogió:", trash_type)

			# Mantener siempre el máximo si quieres:
			if get_active_objects_count() < max_active_objects:
				spawn_random_object()
		else:
			print("[Recolección] Ya lleva una basura. Entrégala primero en un contenedor válido.")

func _on_area_body_exited(body, spawned_obj: Node3D):
	if body == target_vehicle:
		var iid := spawned_obj.get_instance_id()
		_current_colliding.erase(iid)

# ======================================================
# === API para el sistema de entrega ===================
# ======================================================

func has_trash() -> bool:
	return carrying_trash

func get_carried_trash_type() -> String:
	return carried_trash_type

func clear_trash():
	carrying_trash = false
	carried_trash_type = ""

# Entrega y limpia, devuelve el tipo entregado ("" si no llevaba nada)
func deliver_trash() -> String:
	if carrying_trash:
		var t := carried_trash_type
		carrying_trash = false
		carried_trash_type = ""
		return t
	return ""
