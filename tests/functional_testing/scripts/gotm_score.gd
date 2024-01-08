class_name GotmScoreTest
extends Node

var copy_id_to_clipboard := true
var print_console := true


func create_score(is_local: bool = false) -> void:
	var score_name: String = $UI/Parameters/ScoreParameters/Name.text
	var value: float = $UI/Parameters/ScoreParameters/Value.text.to_float()
	var props: Dictionary = _get_properties()
	var score: GotmScore
	if is_local:
		score = await GotmScore.create_local(score_name, value, props)
	else:
		score = await GotmScore.create(score_name, value, props)
	if !score:
		push_error("Could not create score...")
		return
	if copy_id_to_clipboard:
		DisplayServer.clipboard_set(score.id)
	if print_console:
		print("GotmScore created...")
		print(GotmScoreTest.gotm_score_to_string(score))


func create_local_score() -> void:
	create_score(true)


func update_score() -> void:
	var id: String = $"UI/Parameters/ID Parameter/ID".text
	var value = $UI/Parameters/ScoreParameters/Value.text
	if value == "" or value.to_lower() == "null":
		value = null
	else:
		value = value.to_float()
	var props = _get_properties()
	if props.is_empty():
		props = null
	var score := await GotmScore.update(id, value, props)
	if !score:
		push_error("Could not update score with id: ", id)
		return
	if copy_id_to_clipboard:
		DisplayServer.clipboard_set(score.id)
	if print_console:
		print("GotmScore updated...")
		print(GotmScoreTest.gotm_score_to_string(score))


func fetch_score() -> void:
	var id: String = $"UI/Parameters/ID Parameter/ID".text
	var score := await GotmScore.fetch(id)
	if !score:
		push_error("Could not fetch score with id: ", id)
		return

	if copy_id_to_clipboard:
		DisplayServer.clipboard_set(score.id)
	if print_console:
		print("GotmScore fetched...")
		print(GotmScoreTest.gotm_score_to_string(score))


func delete_score() -> void:
	var id: String = $"UI/Parameters/ID Parameter/ID".text
	var result := await GotmScore.delete(id)
	if !result:
		push_error("Could not delete score with id: ", id)
		return
	if print_console:
		print("GotmScore deleted (id: " + id + ") ...")


static func gotm_score_to_string(score: GotmScore) -> String:
	var result := "\nGotmScore:\n"
	result += "[name] " + score.name + "\n"
	result += "[value] " + str(score.value) + "\n"
	result += "[id] " + score.id + "\n"
	result += "[user_id] " + score.user_id + "\n"
	@warning_ignore("integer_division")
	var created := Time.get_datetime_string_from_unix_time(score.created)
	result += "[created] " + created  + "\n"
	result += "[is_local] " + str(score.is_local) + "\n"
	result += "[properties] " + str(score.properties) + "\n"
	return result


func _get_properties() -> Dictionary:
	var prop_1_name: String = $UI/Parameters/ScoreParameters/Property1/Property1Name.text
	var prop_1_value: String = $UI/Parameters/ScoreParameters/Property1/Property1Value.text
	var prop_2_name: String = $UI/Parameters/ScoreParameters/Property2/Property2Name.text
	var prop_2_value: String = $UI/Parameters/ScoreParameters/Property2/Property2Value.text
	var prop_3_name: String = $UI/Parameters/ScoreParameters/Property3/Property3Name.text
	var prop_3_value: String = $UI/Parameters/ScoreParameters/Property3/Property3Value.text
	var props := {}
	if prop_1_name != "":
		props[prop_1_name] = prop_1_value
	if prop_2_name != "":
		props[prop_2_name] = prop_2_value
	if prop_3_name != "":
		props[prop_3_name] = prop_3_value
	return props


func _check_buttons(_param = null) -> void:
	# Create Score Button
	if ($UI/Parameters/ScoreParameters/Name.text != ""
		&& $UI/Parameters/ScoreParameters/Value.text != ""):
			$UI/Menu/CreateScore.disabled = false
	else:
		$UI/Menu/CreateScore.disabled = true
	# Create Local Score Button
	if ($UI/Parameters/ScoreParameters/Name.text != ""
		&& $UI/Parameters/ScoreParameters/Value.text != ""):
			$UI/Menu/CreateLocalScore.disabled = false
	else:
		$UI/Menu/CreateLocalScore.disabled = true
	# Update Score Button
	if $"UI/Parameters/ID Parameter/ID".text != "":
		$UI/Menu/UpdateScore.disabled = false
	else:
		$UI/Menu/UpdateScore.disabled = true
	# Fetch Score Button
	if $"UI/Parameters/ID Parameter/ID".text != "":
		$UI/Menu/FetchScore.disabled = false
	else:
		$UI/Menu/FetchScore.disabled = true
	# Delete Score Button
	if $"UI/Parameters/ID Parameter/ID".text != "":
		$UI/Menu/DeleteScore.disabled = false
	else:
		$UI/Menu/DeleteScore.disabled = true


func _on_copy_id_toggled(button_pressed: bool):
	copy_id_to_clipboard = button_pressed


func _on_console_print_toggled(button_pressed: bool) -> void:
	print_console = button_pressed
