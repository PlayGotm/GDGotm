@tool
extends EditorPlugin

var toolbar: Control = preload("res://addons/gdgotm/toolbar/toolbar.tscn").instantiate()


func _enter_tree() -> void:
	toolbar.scale_toolbar_icon(get_editor_interface().get_editor_scale())
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar)
	toolbar.queue_free()
