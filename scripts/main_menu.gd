extends Control


func _on_buttonmodeling_pressed() -> void:
	get_tree().change_scene_to_file("res://modeling.tscn")
