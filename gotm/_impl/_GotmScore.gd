# MIT License
#
# Copyright (c) 2020-2022 Macaroni Studios AB
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name _GotmScore
#warnings-disable

static func get_implementation():
	if not Gotm.is_live() and not Gotm.get_config().experimentalForceLiveScoresApi:
		return _GotmScoreDevelopment
	return _GotmStore

static func get_auth_implementation():
	if get_implementation() == _GotmScoreDevelopment:
		return _GotmAuthDevelopment
	return _GotmAuth

static func create(score, name: String, value: float, properties: Dictionary = {}):
	var data = yield(get_implementation().create("scores", {"name": name, "value": value, "properties": properties}), "completed")
	return _format(data, score)


static func update(score, value = null, properties = null):
	var data = yield(get_implementation().update(score.id, _GotmUtility.delete_null({"value": value, "properties": properties})), "completed")
	return _format(data, score)

static func delete(score) -> void:
	yield(get_implementation().delete(score.id), "completed")

static func fetch(score, id: String):
	var data = yield(get_implementation().fetch(id), "completed")
	return _format(data, score)

static func list(GotmScoreType, leaderboard, after: String, ascending: bool) -> Array:
	var project = _get_project()
	if project is GDScriptFunctionState:
		project = yield(project, "completed")
	if not project:
		return []
	var data_list = yield(get_implementation().list("scores", "byScoreSort", _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"author": leaderboard.user_id,
		"after": after,
		"descending": not ascending,
	})), "completed")
	var scores = []
	for data in data_list:
		scores.append(_format(data, GotmScoreType.new()))
	return scores 

static func get_rank(leaderboard, score_id_or_value) -> int:
	var project = _get_project()
	if project is GDScriptFunctionState:
		project = yield(project, "completed")
	if not project:
		return 0
	var params = _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"author": leaderboard.user_id,
	})
	if score_id_or_value is int:
		params.value = score_id_or_value
	elif score_id_or_value and score_id_or_value is String:
		params.score = score_id_or_value
	else:
		return 0
	var stat = yield(get_implementation().fetch("stats/rank", "rankByScoreSort", params), "completed")
	if not stat:
		return 0
	return stat.value

static func get_counts(leaderboard, minimum_value, maximum_value, segment_count) -> Array:
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
	if not project:
		return counts
	
	var params = _GotmUtility.delete_empty({
		"name": leaderboard.name,
		"target": project,
		"props": leaderboard.properties,
		"period": leaderboard.period.to_string(),
		"isUnique": leaderboard.is_unique,
		"author": leaderboard.user_id,
		"limit": segment_count,
	})
	if minimum_value is float:
		params.min = minimum_value
	if maximum_value is float:
		params.max = maximum_value
	var stats = yield(get_implementation().list("stats", "countByScoreSort", params), "completed")
	
	if stats.size() != counts.size():
		return counts
	
	for i in range(stats.size()):
		counts[i] = stats[i].value
	return counts

static func _get_project() -> String:
	var Auth = get_auth_implementation()
	var token = Auth.get_token()
	if not token:
		token = yield(Auth.get_token_async(), "completed")
	return Auth.get_project_from_token(token)

static func _format(data, score):
	if not data or not score:
		return
	score.id = data.path
	score.user_id = data.author
	score.name = data.name
	score.value = data.value
	score.properties = data.properties
	score.created = _GotmUtility.get_unix_time_from_iso(data.created)
	return score
	
	
	
	
	

