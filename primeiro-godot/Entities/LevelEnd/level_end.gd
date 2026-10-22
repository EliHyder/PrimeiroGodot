extends Area2D

@export var next_level: String = ""

func _on_body_entered(_body: Node2D) -> void:
	call_deferred("load_next_scene")
	


func load_next_scene() -> void:
	print(get_tree_string())
	get_tree().change_scene_to_file("res://Scenes/%s/%s.tscn" % [next_level, next_level])
