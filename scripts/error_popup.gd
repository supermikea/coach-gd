extends PopupPanel

func _on_button_pressed() -> void:
	queue_free()


func _on_popup_hide() -> void:
	queue_free()
