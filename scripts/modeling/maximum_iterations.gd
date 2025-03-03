extends LineEdit



func _on_text_changed(new_text: String) -> void:
	if not new_text:
		%"maximum_iterations_label".label_settings.font_color = Color(255, 255, 255)
		%"maximum_iterations_label".text = "maximum iterations: "
	elif not new_text.is_valid_int():
		%"maximum_iterations_label".label_settings.font_color = Color(255, 0, 0)
		%"maximum_iterations_label".text = "Needs to be valid Integer!"
	else:
		%"maximum_iterations_label".label_settings.font_color = Color(255, 255, 255)
		%"maximum_iterations_label".text = "maximum iterations: "
