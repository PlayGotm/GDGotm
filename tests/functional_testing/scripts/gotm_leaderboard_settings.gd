class_name LeaderboardSettings
extends Popup

signal user_updated

const PERIOD_OPTIONS := ["All", "Last Day", "Last Week", "Last Month", "Last Year"]

@onready var initial_window_position: Vector2i = position
@onready var tab_count: int = $TabContainer.get_tab_count()
var data: Dictionary


func get_leaderboard(leaderboard_number: int) -> GotmLeaderboard:
	if leaderboard_number <= 0 || leaderboard_number > tab_count:
		return null
	return data["L" + str(leaderboard_number)]


func _ready() -> void:
	# handle closing of window
	close_requested.connect(func(): hide())
	# init menus
	_init_period_menus()
	# init data
	for tab_number in tab_count:
		data["L" + str(tab_number + 1)] = GotmLeaderboard.new()


func _on_leaderboard_settings_pressed() -> void:
	position = initial_window_position
	show()

# inefficient but couldn't bother with so many inputs
func _on_user_input(_param = null) -> void:
	for tab_number in tab_count:
		var board_name: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Name").text
		var period: int = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Period").selected
		var user_id: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/UserID").text
		var prop1name: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property1/P1Name").text
		var prop1value: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property1/P1Value").text
		var prop2name: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property2/P2Name").text
		var prop2value: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property2/P2Value").text
		var prop3name: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property3/P3Name").text
		var prop3value: String = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Property3/P3Value").text
		var is_unique: bool = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer2/Grid/Unique").button_pressed
		var is_inverted: bool = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer2/Grid/Inverted").button_pressed
		var is_oldest_first: bool = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer2/Grid/OldestFirst").button_pressed
		var is_local: bool = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer2/Grid/Local").button_pressed

		var leaderboard: GotmLeaderboard = data["L" + str(tab_number + 1)]
		leaderboard.name = board_name
		leaderboard.period = _to_gotm_period(PERIOD_OPTIONS[period])
		leaderboard.user_id = user_id
		leaderboard.properties.clear()
		if !prop1name.is_empty():
			leaderboard.properties[prop1name] = prop1value
		if !prop2name.is_empty():
			leaderboard.properties[prop2name] = prop2value
		if !prop3name.is_empty():
			leaderboard.properties[prop3name] = prop3value
		leaderboard.is_unique = is_unique
		leaderboard.is_inverted = is_inverted
		leaderboard.is_oldest_first = is_oldest_first
		leaderboard.is_local = is_local
		emit_signal("user_updated")


func _init_period_menus() -> void:
	for tab_number in tab_count:
		var period_node: OptionButton = get_node("TabContainer/Leaderboard " + str(tab_number+1) + "/CenterContainer1/Grid/Period")
		for option in PERIOD_OPTIONS:
			period_node.add_item(option)
		period_node.selected = 0


func _to_gotm_period(str_period: String) -> GotmPeriod:
	match str_period:
		"All": return GotmPeriod.all()
		"Last Day": return GotmPeriod.sliding(GotmPeriod.TimeGranularity.DAY)
		"Last Week": return GotmPeriod.sliding(GotmPeriod.TimeGranularity.WEEK)
		"Last Month": return GotmPeriod.sliding(GotmPeriod.TimeGranularity.MONTH)
		"Last Year": return GotmPeriod.sliding(GotmPeriod.TimeGranularity.YEAR)
		_: return GotmPeriod.all()
