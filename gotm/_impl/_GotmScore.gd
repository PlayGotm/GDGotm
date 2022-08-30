class_name _GotmScore
#warnings-disable




static func get_implementation(id = null):
	var config := _Gotm.get_config()
	if !_Gotm.is_global_api("scores") || _LocalStore.fetch(id):
		return _GotmScoreLocal
	return _GotmStore

static func get_auth_implementation():
	if get_implementation() == _GotmScoreLocal:
		return _GotmAuthLocal
	return _GotmAuth

static func create(name: String, value: float, properties: Dictionary = {}, is_local: bool = false):
	value = _GotmUtility.clean_for_json(value)
	properties = _GotmUtility.clean_for_json(properties)
	var implementation = _GotmScoreLocal if is_local else get_implementation()
	var data = yield(implementation.create("scores", {"name": name, "value": value, "props": properties}), "completed")
	if data:
		_clear_cache()
	return _format(data, _Gotm.create_instance("GotmScore"))


static func update(score_or_id, value = null, properties = null):
	var id = _coerce_id(score_or_id)
	value = _GotmUtility.clean_for_json(value)
	properties = _GotmUtility.clean_for_json(properties)
	var data = yield(get_implementation(id).update(id, _GotmUtility.delete_null({"value": value, "props": properties})), "completed")
	if data:
		_clear_cache()
	return _format(data, _Gotm.create_instance("GotmScore") if id is String else score_or_id)

static func delete(score_or_id) -> void:
	var id = _coerce_id(score_or_id)
	yield(get_implementation(id).delete(id), "completed")
	_clear_cache()

static func fetch(score_or_id):
	var id = _coerce_id(score_or_id)
	var data = yield(get_implementation(id).fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmScore"))

static func encode_cursor(score_id_or_value, ascending: bool) -> String:
	score_id_or_value = _GotmUtility.clean_for_json(score_id_or_value)
	if score_id_or_value is String:
		var score = yield(fetch(score_id_or_value), "completed")
		if !score:
			return ""
		return _GotmUtility.encode_cursor([[score.value, score.created], score.id.replace("/", "-") + "~"])
	elif score_id_or_value is float || score_id_or_value is int:
		yield(_GotmUtility.get_tree(), "idle_frame")
		var created = 253402300799000 if ascending else 0
		return _GotmUtility.encode_cursor([[float(score_id_or_value), created], "~"])
	
	return ""

static func list_by_rank(leaderboard, after, ascending: bool) -> Array:
	if after is float:
		after = int(after)
	return yield(_list(leaderboard, after, ascending), "completed")

static func list(leaderboard, after, ascending: bool) -> Array:
	if after is int:
		after = float(after)
	return yield(_list(leaderboard, after, ascending), "completed")

static func _list(leaderboard, after, ascending: bool, limit: int = 0) -> Array:
	after = _coerce_id(after)
	var after_id = after if after && after is String else null
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project:
		return []
	var after_rank = null
	if after && after is String || after is float:
		after = yield(encode_cursor(after, ascending), "completed")
	elif after is int:
		after_rank = after
		after = null
	else:
		after = null
	var params = _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"isInverted": leaderboard.is_inverted,
		"isOldestFirst": leaderboard.is_oldest_first,
		"author": leaderboard.user_id,
		"after": after,
		"descending": !ascending,
		"limit": limit
	})
	if after_rank is int:
		params.afterRank = after_rank
	var implementation = _GotmScoreLocal if leaderboard.is_local else get_implementation(after_id)
	var data_list = yield(implementation.list("scores", "byScoreSort", params), "completed")
	if !data_list:
		return []
		
	var scores = []
	for data in data_list:
		scores.append(_format(data, _Gotm.create_instance("GotmScore")))
	return scores 


static func get_rank(leaderboard, score_id_or_value) -> int:
	score_id_or_value = _coerce_id(score_id_or_value)
	score_id_or_value = _GotmUtility.clean_for_json(score_id_or_value)
	var project = _get_project()
	var has_yielded := false
	if project is GDScriptFunctionState:
		project = yield(project, "completed")
		has_yielded = true
	if !project:
		if !has_yielded:
			yield(_GotmUtility.get_tree(), "idle_frame")
		return 0
	var params = _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"isInverted": leaderboard.is_inverted,
		"isOldestFirst": leaderboard.is_oldest_first,
		"author": leaderboard.user_id,
	})
	if score_id_or_value is float || score_id_or_value is int:
		params.value = float(score_id_or_value)
	elif score_id_or_value && score_id_or_value is String:
		params.score = score_id_or_value
	else:
		if !has_yielded:
			yield(_GotmUtility.get_tree(), "idle_frame")
		return 0
	var implementation = _GotmScoreLocal if leaderboard.is_local else get_implementation(params.get("score"))
	var stat = yield(implementation.fetch("stats/rank", "rankByScoreSort", params), "completed")
	if !stat:
		return 0
	return stat.value

static func get_counts(leaderboard, minimum_value, maximum_value, segment_count) -> Array:
	minimum_value = _GotmUtility.clean_for_json(minimum_value)
	maximum_value = _GotmUtility.clean_for_json(maximum_value)
	segment_count = _GotmUtility.clean_for_json(segment_count)
	
	if segment_count > 20:
		segment_count = 20
	if segment_count < 1:
		segment_count = 1
	var project = _get_project()
	if project is GDScriptFunctionState:
		project = yield(project, "completed")
	var counts := []
	for i in range(0, segment_count):
		counts.append(0)
	if !project:
		return counts
	
	var params = _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"isInverted": leaderboard.is_inverted,
		"isOldestFirst": leaderboard.is_oldest_first,
		"author": leaderboard.user_id,
		"limit": segment_count,
	})
	if minimum_value is float || minimum_value is int:
		params.min = float(minimum_value)
	if maximum_value is float || maximum_value is int:
		params.max = float(maximum_value)
	var implementation = _GotmScoreLocal if leaderboard.is_local else get_implementation()
	var stats = yield(implementation.list("stats", "countByScoreSort", params), "completed")
	
	if stats.size() != counts.size():
		return counts
	
	for i in range(stats.size()):
		counts[i] = stats[i].value
	return counts

static func _clear_cache():
	get_implementation().clear_cache("scores")
	get_implementation().clear_cache("stats")

static func _get_project() -> String:
	var Auth = get_auth_implementation()
	var auth = Auth.get_auth()
	if !auth:
		auth = yield(Auth.get_auth_async(), "completed")
	if !auth:
		return
	return auth.project

static func _format(data, score):
	if !data || !score:
		return
	score.id = data.path
	score.user_id = data.author
	score.name = data.name
	score.value = float(data.value)
	score.properties = data.props if data.get("props") else {}
	score.created = data.created
	score.is_local = !!_LocalStore.fetch(data.path)
	return score


static func _coerce_id(resource_or_id):
	return _GotmUtility.coerce_resource_id(resource_or_id, "scores")