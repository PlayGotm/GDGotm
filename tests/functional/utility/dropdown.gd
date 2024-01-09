extends OptionButton

const scenes := [
	"res://tests/functional/score_functional_test.tscn",
	"res://tests/functional/leaderboard_functional_test.tscn",
	"res://tests/functional/user_functional_test.tscn",
	"res://tests/functional/auth_functional_test.tscn",
	"res://tests/functional/content_functional_test.tscn"
]

static var scene_cache := {}
static var current_scene_index := -1

func _enter_tree() -> void:
	update_selected()


func switch_scenes(index: int) -> void:
	# get new scene
	var new_scene_file_path: String = scenes[index]
	var new_scene_node: Node = scene_cache.get(index)
	if !new_scene_node:
		new_scene_node = load(new_scene_file_path).instantiate()
		scene_cache[index] = new_scene_node
	
	current_scene_index = index
	# get old scene
	var old_scene_node: Node = get_tree().root.get_child(0)
	var old_scene_index: int = scenes.find(old_scene_node.scene_file_path)
	# switch scenes manually
	get_tree().root.add_child(new_scene_node)
	get_tree().current_scene = new_scene_node
	get_tree().root.remove_child(old_scene_node)


func update_selected() -> void:
	if current_scene_index != -1:
		selected = current_scene_index
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
