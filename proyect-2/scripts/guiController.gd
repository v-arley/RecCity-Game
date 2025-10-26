extends Control
class_name HUDController

# Referencias a Labels de conteo por tipo de basura
@export var lbl_count_paper: Label
@export var lbl_count_glass: Label
@export var lbl_count_metal: Label
@export var lbl_count_plastic: Label
@export var lbl_count_general: Label

# Referencias a Labels de totales
@export var lbl_corrects: Label
@export var lbl_incorrects: Label

# Contadores internos
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
# === FUNCIONES PÚBLICAS DE ACTUALIZACIÓN ==============
# ======================================================

func add_correct(trash_type: String):
	total_corrects += 1
	lbl_corrects.text = str("Corrects: ", total_corrects)

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

func add_incorrect():
	total_incorrects += 1
	lbl_incorrects.text = str("Incorrects: ", total_incorrects)

func reset_all():
	for key in counts.keys():
		counts[key] = 0
	total_corrects = 0
	total_incorrects = 0
	_update_all_labels()

func _update_all_labels():
	lbl_count_paper.text = str(counts["Paper"])
	lbl_count_glass.text = str(counts["Glass"])
	lbl_count_metal.text = str(counts["Metal"])
	lbl_count_plastic.text = str(counts["Plastic"])
	lbl_count_general.text = str(counts["General"])
	lbl_corrects.text = str("Corrects: ", total_corrects)
	lbl_incorrects.text = str("Incorrects: ",total_incorrects)
