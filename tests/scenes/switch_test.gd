class_name SwitchTest
extends OptionButton

const scenes := [
	"res://functional_testing/gotm_score.tscn",
	"res://functional_testing/gotm_leaderboard.tscn",
	"res://functional_testing/gotm_user.tscn",
	"res://functional_testing/gotm_auth.tscn",
	"res://functional_testing/gotm_content.tscn"
	]


func _enter_tree() -> void:
	update_selected()


func switch_scenes(index: int) -> void:
	# get new scene
	var new_scene_file_path: String = scenes[index]
	var new_scene_node: Node
	if (SwitchTest as Script).has_meta("sceneindex" + str(index)): # using like a static variable
		new_scene_node = (SwitchTest as Script).get_meta("sceneindex" + str(index))
	else:
		new_scene_node = load(new_scene_file_path).instantiate()
	# store new scene index as a static variable
	(SwitchTest as Script).set_meta("current_scene_index", index)
	# get old scene
	var old_scene_node: Node = get_tree().root.get_child(0)
	var old_scene_index: int = scenes.find(old_scene_node.scene_file_path)
	# switch scenes manually
	get_tree().root.add_child(new_scene_node)
	get_tree().current_scene = new_scene_node
	get_tree().root.remove_child(old_scene_node)
	# store old scene for reuse
	(SwitchTest as Script).set_meta("sceneindex" + str(old_scene_index), old_scene_node)


func update_selected() -> void:
	var current_index: int = (SwitchTest as Script).get_meta("current_scene_index", -1)
	if current_index != -1:
		selected = current_index
		return
	var current_path := get_tree().current_scene.scene_file_path
	for n in scenes.size():
		if scenes[n] == current_path:
			selected = n
			break


func _on_item_selected(index: int) -> void:
	if scenes[index] == get_tree().current_scene.scene_file_path:
		return
	switch_scenes(index)
