class_name GotmLeaderboardTest
extends Node

@onready var settings: LeaderboardSettings = get_node("UI/LeaderboardSettings")
var current_leaderboard: GotmLeaderboard
var print_console := true


func get_rank() -> void:
	var result: int
	var id_value_str: String = $UI/Parameters/LeaderboardParameters/IDValue.text

	if id_value_str.is_valid_float():
		result = await current_leaderboard.get_rank(id_value_str.to_float())
	else:
		result = await current_leaderboard.get_rank(id_value_str)

	if print_console:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get rank called...")
		print("Rank: ", result)


func get_scores(by_rank := false) -> void:
	var results: Array
	var after_id_value = $UI/Parameters/LeaderboardParameters/AfterIDValue.text
	var is_ascending: bool = $UI/Parameters/LeaderboardParameters/Ascending.button_pressed

	if after_id_value.is_valid_float():
		after_id_value = after_id_value.to_float()

	if by_rank:
		results = await  current_leaderboard.get_scores_by_rank(after_id_value, is_ascending)
	else:
		results = await  current_leaderboard.get_scores(after_id_value, is_ascending)

	if print_console && !by_rank:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get scores called...")
	elif print_console && by_rank:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get scores by rank called...")
	if print_console:
		for score in results:
			print(GotmScoreTest.gotm_score_to_string(score))


func get_scores_by_rank() -> void:
	get_scores(true)


func get_surrounding(by_rank := false) -> void:
	var results: GotmLeaderboard.SurroundingScores
	var id_value = $UI/Parameters/LeaderboardParameters/IDValue2.text

	if id_value.is_valid_float():
		id_value = id_value.to_float()

	if by_rank:
		results = await current_leaderboard.get_surrounding_scores_by_rank(id_value)
	else:
		results = await current_leaderboard.get_surrounding_scores(id_value)

	if print_console && !by_rank:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get surrounding called...")
	elif print_console && by_rank:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get surrounding by rank called...")
	if print_console && results.is_valid():
		print("---BEFORE---")
		for score in results.before:
			print(GotmScoreTest.gotm_score_to_string(score))
		print("---SCORE---")
		print(GotmScoreTest.gotm_score_to_string(results.score))
		print("---AFTER---")
		for score in results.after:
			print(GotmScoreTest.gotm_score_to_string(score))


func get_surrounding_by_rank() -> void:
	get_surrounding(true)


func get_count() -> void:
	var result := await current_leaderboard.get_count()
	if print_console:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get count called...")
		print("Count: ", result)


func get_counts() -> void:
	var minimum = $UI/Parameters/LeaderboardParameters/HBoxContainer1/Min.text
	var maximum = $UI/Parameters/LeaderboardParameters/HBoxContainer2/Max.text
	var segments = $UI/Parameters/LeaderboardParameters/Segments.text

	minimum = minimum.to_float() if minimum.is_valid_float() else -INF
	maximum = maximum.to_float() if maximum.is_valid_float() else INF
	segments = segments.to_float() if segments.is_valid_float() else 20

	var result := await current_leaderboard.get_counts(minimum, maximum, segments)
	if print_console:
		print("\nGotmLeaderboard [" + current_leaderboard.name + "] get counts called...")
		print("Counts: ", result)


func _ready() -> void:
	_add_leaderboards()
	_update_current_leaderboard()


func _add_leaderboards() -> void:
	for n in settings.tab_count:
		$UI/Parameters/HBoxContainer/Leaderboard.add_item("Leaderboard " + str(n + 1))
	$UI/Parameters/HBoxContainer/Leaderboard.selected = 0


func _update_current_leaderboard(_param = null) -> void:
	var leaderboard_number: int = $UI/Parameters/HBoxContainer/Leaderboard.selected + 1
	current_leaderboard = settings.get_leaderboard(leaderboard_number)
	_update_buttons()


func _update_buttons(_param = null) -> void:
	var get_rank_button: Button = $UI/ScrollContainer/Menu/GetRank
	var get_scores_button: Button = $UI/ScrollContainer/Menu/GetScores
	var get_scores_rank_button: Button = $UI/ScrollContainer/Menu/GetScoresByRank
	var get_surr_button: Button = $UI/ScrollContainer/Menu/GetSurrounding
	var get_surr_rank_button: Button = $UI/ScrollContainer/Menu/GetSurroundingByRank
	var get_count_button: Button = $UI/ScrollContainer/Menu/GetCount
	var get_counts_button: Button = $UI/ScrollContainer/Menu/GetCounts
	
	var is_disable_all := true if current_leaderboard.name.is_empty() else false
	get_rank_button.disabled = is_disable_all
	get_scores_button.disabled = is_disable_all
	get_scores_rank_button.disabled = is_disable_all
	get_surr_button.disabled = is_disable_all
	get_surr_rank_button.disabled = is_disable_all
	get_count_button.disabled = is_disable_all
	get_counts_button.disabled = is_disable_all
	if is_disable_all:
		return

	# Get Rank Button
	if $UI/Parameters/LeaderboardParameters/IDValue.text == "":
		get_rank_button.disabled = true
	else:
		get_rank_button.disabled = false
	# Get Surrounding Buttons
	if $UI/Parameters/LeaderboardParameters/IDValue2.text == "":
		get_surr_button.disabled = true
		get_surr_rank_button.disabled = true
	else:
		get_surr_button.disabled = false
		get_surr_rank_button.disabled = false


func _on_console_print_toggled(button_pressed: bool) -> void:
	print_console = button_pressed
