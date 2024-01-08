extends Node

enum Test { FUNCTIONAL, UNIT }

var force_offline := false
var test: Test


func _enter_tree() -> void:
	get_tree().root.gui_embed_subwindows = true



func switch_test_scenes() -> void:
	match test:
		Test.FUNCTIONAL:
			get_tree().change_scene_to_file("res://tests/functional_testing/gotm_score.tscn")
		Test.UNIT:
			get_tree().change_scene_to_file("res://tests/unit_testing/temp.tscn")


func _on_gotm_init_pressed() -> void:
	Gotm.project_key = $UI/FunctionalMenu/ProjectKey.text
	Gotm.force_local_contents = force_offline
	Gotm.force_local_marks = force_offline
	Gotm.force_local_scores = force_offline
	if force_offline:
		print("Forcing offline...")
	switch_test_scenes()


func _on_offline_toggled(button_pressed: bool) -> void:
	force_offline = button_pressed


func _on_start_functional_pressed() -> void:
	test = Test.FUNCTIONAL
	$UI/Menu.hide()
	$UI/FunctionalMenu.show()


func _on_start_unit_pressed() -> void:
	test = Test.UNIT
	$UI/Menu.hide()
	$UI/FunctionalMenu.show()
