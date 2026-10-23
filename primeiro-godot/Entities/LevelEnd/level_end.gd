extends Area2D

@export var next_level: String = ""


func get_quant_enimies():
	var quant_enimies: int = 0
	for enimie in get_tree().get_nodes_in_group("Enimies"):
		if not enimie.get_meta("Dead"):
			quant_enimies += 1
	print(quant_enimies)
	return quant_enimies

func _on_body_entered(_body: Node2D) -> void:
	
	if get_quant_enimies() > 0: return
	call_deferred("load_next_scene")
	
func load_next_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/%s/%s.tscn" % [next_level, next_level])
