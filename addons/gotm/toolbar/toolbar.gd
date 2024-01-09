@tool
extends Panel


func scale_toolbar_icon(editor_scale: float) -> void:
	var original_size: float = 44 / 1.5 # orignally designed for 1.5 editor scale, 44 is the max size without expanding the editor
	var new_size: float = editor_scale * original_size
	custom_minimum_size = Vector2(new_size, new_size)
