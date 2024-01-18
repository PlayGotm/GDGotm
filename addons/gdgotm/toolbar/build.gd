@tool
extends Node

const EXPORT_DIR := "res://addons/gdgotm/exports/"
const EXPORT_PRESETS := "res://export_presets.cfg"


func build() -> bool:
	print("[GDGotm] Building project...")
	if !_has_web_export_preset():
		push_error("[GDGotm] Failed to build project. Go to 'Project -> Exports...' and make sure there is a Web preset. It must have the name 'Web'.")
		_alert_error()
		return false

	_create_dir()
	if OS.get_name() == "macOS":
		return _build_macOS()

	var project_location := get_project_location()
	var output := []
	var args: PackedStringArray = ["--headless", "--export-pack", "Web", project_location]
	var exit_code = OS.execute(OS.get_executable_path(), args, output, true)
	if exit_code == -1:
		push_error("[GDGotm] Failed to build project. Bad execute.")
		_alert_error()
	var output_string: String = output[0]
	if !output_string.contains("savepack: end"):
		push_error("[GDGotm] Errors during build. Log:\n", output_string)
		_alert_error()
		return false
	return true


func get_project_location() -> String:
	var project_name: String = ProjectSettings.get_setting("application/config/name", "")
	if project_name.is_empty():
		project_name = "GotmGame"
	return EXPORT_DIR + project_name + ".pck"


func _build_macOS() -> bool:
	var project_location := get_project_location()
	# remove any old exports
	DirAccess.remove_absolute(project_location)
	var args: PackedStringArray = ["--headless", "--export-pack", "Web", project_location]
	var instance_id := OS.create_instance(args)
	if instance_id == -1:
		push_error("[GDGotm] Failed to build project. Bad execute on macOS.")
		_alert_error()
		return false

	# validate .pck export since 'create_instance' doesn't have logging
	while(OS.is_process_running(instance_id)): pass # wait for build to finish
	if !FileAccess.file_exists(project_location):
		push_error("[GDGotm] Failed to build project on macOS.\nTry building/exporting normally to see if you encounter any errors.")
		_alert_error()
		return false
	return true


func _has_web_export_preset() -> bool:
	if !FileAccess.file_exists(EXPORT_PRESETS):
		return false
	var export_presets := FileAccess.get_file_as_string(EXPORT_PRESETS)
	if !export_presets.contains("name=\"Web\""):
		return false
	return true


func _create_dir() -> void:
	if DirAccess.dir_exists_absolute(EXPORT_DIR):
		return
	DirAccess.make_dir_recursive_absolute(EXPORT_DIR)
	var file := FileAccess.open(EXPORT_DIR + ".gdignore", FileAccess.WRITE)
	if file == null:
		push_error("[GDGotm FileAccess Error " + str(FileAccess.get_open_error()) + "] Cannot write file to "+ EXPORT_DIR + ".")
	else:
		file.close()
	file = FileAccess.open(EXPORT_DIR + ".gitignore", FileAccess.WRITE)
	if file == null:
		push_error("[GDGotm FileAccess Error " + str(FileAccess.get_open_error()) + "] Cannot write file to "+ EXPORT_DIR + ".")
	else:
		file.store_string("# Ignore this directory\n*")
		file.close()


func _alert_error() -> void:
	OS.alert("GDGotm Plugin Build Error.\nPlease look at the errors inside Godot's debugger.", "GDGotm Plugin Build Error")
