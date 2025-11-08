extends Control
class_name HUDController

# ======================================================
# === LABELS DEL HUD (pantalla principal) ==============
# ======================================================

@export var lbl_count_paper: Label
@export var lbl_count_glass: Label
@export var lbl_count_metal: Label
@export var lbl_count_plastic: Label
@export var lbl_count_general: Label

@export var lbl_corrects: Label
@export var lbl_incorrects: Label

# ======================================================
# === LABELS DE GAME OVER ==============================
# ======================================================

@export var lbl_go_paper: Label
@export var lbl_go_glass: Label
@export var lbl_go_metal: Label
@export var lbl_go_plastic: Label
@export var lbl_go_general: Label
@export var lbl_go_corrects: Label
@export var lbl_go_incorrects: Label
@export var lbl_go_total: Label
@export var lbl_go_accuracy: Label

# ======================================================
# === LABELS DE TÍTULO PARA RESALTAR ===================
# ======================================================

@export var lbl_tag_plastico: Label
@export var lbl_tag_vidrio: Label
@export var lbl_tag_papel: Label
@export var lbl_tag_organico: Label
@export var lbl_tag_metal: Label

# ======================================================
# === CONTADORES INTERNOS ==============================
# ======================================================

var counts := {
	"Paper": 0,
	"Glass": 0,
	"Metal": 0,
	"Plastic": 0,
	"General": 0
}

var total_corrects := 0
var total_incorrects := 0

# ======================================================
# === FUNCIONES PÚBLICAS ===============================
# ======================================================

func add_correct(trash_type: String):
	total_corrects += 1
	lbl_corrects.text = "Corrects: %d" % total_corrects

	match trash_type:
		"Paper", "Papel":
			counts["Paper"] += 1
			lbl_count_paper.text = str(counts["Paper"])
		"Glass", "Vidrio":
			counts["Glass"] += 1
			lbl_count_glass.text = str(counts["Glass"])
		"Metal":
			counts["Metal"] += 1
			lbl_count_metal.text = str(counts["Metal"])
		"Plastic", "Plastico":
			counts["Plastic"] += 1
			lbl_count_plastic.text = str(counts["Plastic"])
		"Organico", "General":
			counts["General"] += 1
			lbl_count_general.text = str(counts["General"])

	_update_game_over_labels()

func add_incorrect():
	total_incorrects += 1
	lbl_incorrects.text = "Incorrects: %d" % total_incorrects
	_update_game_over_labels()

func reset_all():
	for key in counts.keys():
		counts[key] = 0
	total_corrects = 0
	total_incorrects = 0
	_update_all_labels()
	_clear_highlight()

# ======================================================
# === ACTUALIZACIÓN GENERAL ============================
# ======================================================

func _update_all_labels():
	lbl_count_paper.text = str(counts["Paper"])
	lbl_count_glass.text = str(counts["Glass"])
	lbl_count_metal.text = str(counts["Metal"])
	lbl_count_plastic.text = str(counts["Plastic"])
	lbl_count_general.text = str(counts["General"])
	lbl_corrects.text = "Corrects: %d" % total_corrects
	lbl_incorrects.text = "Incorrects: %d" % total_incorrects
	_update_game_over_labels()

# ======================================================
# === ACTUALIZA TAMBIÉN LOS LABELS DEL GAME OVER =======
# ======================================================

func _update_game_over_labels():
	if lbl_go_paper:
		lbl_go_paper.text = str(counts["Paper"])
	if lbl_go_glass:
		lbl_go_glass.text = str(counts["Glass"])
	if lbl_go_metal:
		lbl_go_metal.text = str(counts["Metal"])
	if lbl_go_plastic:
		lbl_go_plastic.text = str(counts["Plastic"])
	if lbl_go_general:
		lbl_go_general.text = str(counts["General"])

	if lbl_go_corrects:
		lbl_go_corrects.text = "Corrects: %d" % total_corrects
	if lbl_go_incorrects:
		lbl_go_incorrects.text = "Incorrects: %d" % total_incorrects

	# Totales adicionales
	var total := total_corrects + total_incorrects
	if lbl_go_total:
		lbl_go_total.text = "Entregas totales: %d" % total

	if lbl_go_accuracy:
		var acc := 0
		if total > 0:
			acc = int((float(total_corrects) / total) * 100)
		lbl_go_accuracy.text = "Eficiencia: %d%%" % acc

# ======================================================
# === EFECTOS VISUALES DE RESALTADO ====================
# ======================================================

func highlight_trash(trash_type: String):
	_clear_highlight()
	if trash_type == "" or trash_type == null:
		return

	match trash_type:
		"Plastico", "Plastic":
			_apply_highlight(lbl_tag_plastico)
		"Vidrio", "Glass":
			_apply_highlight(lbl_tag_vidrio)
		"Papel", "Paper":
			_apply_highlight(lbl_tag_papel)
		"Organico", "General":
			_apply_highlight(lbl_tag_organico)
		"Metal":
			_apply_highlight(lbl_tag_metal)

func _apply_highlight(label: Label) -> void:
	if label == null: return
	label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # Borde negro

func _clear_highlight() -> void:
	for lbl in _all_highlight_labels():
		if lbl == null: continue
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_constant_override("outline_size", 0)

func _all_highlight_labels() -> Array:
	return [
		lbl_tag_plastico,
		lbl_tag_vidrio,
		lbl_tag_papel,
		lbl_tag_organico,
		lbl_tag_metal
	]
