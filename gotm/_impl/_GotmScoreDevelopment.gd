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

class_name _GotmScoreDevelopment
#warnings-disable

const _scores = {}


static func create(api: String, data: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	var score = {
		"path": _GotmUtility.create_resource_path(api),
		"author": _GotmAuthDevelopment.get_user(),
		"name": data.name,
		"value": data.value,
		"properties": data if data else {},
		"created": _GotmUtility.get_iso_from_unix_time(OS.get_unix_time(), OS.get_ticks_msec() % 1000)
	}
	_scores[score.path] = score
	return score
#
static func update(id: String, data: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	var score = _scores[id]
	if not score:
		return
	for key in data:
		score[key] = data[key]
	return score

static func delete(id: String) -> void:
	yield(_GotmUtility.get_tree(), "idle_frame")
	_scores.erase(id)

static func fetch(path: String, query: String = "", params: Dictionary = {}, authenticate: bool = false) -> Dictionary:
	yield(_GotmUtility.get_tree(), "idle_frame")
	var path_parts = path.split("/")
	var api = path[0]
	var id = path[1]
	if api == "stats" and id == "rank" and query == "rankByScoreSort":
		return {"path": _GotmStore.create_request_path(path, query, params), "value": _fetch_rank(params)}
	return _scores[path]

static func list(api: String, query: String, params: Dictionary = {}, authenticate: bool = false) -> Array:
	yield(_GotmUtility.get_tree(), "idle_frame")
	if api == "scores" and query == "byScoreSort":
		return _fetch_by_score_sort(params)
	return []

static func _fetch_rank(params) -> int:
	params = _GotmUtility.copy(params, {})
	params.descending = true
	var scores = _fetch_by_score_sort(params)
	var match_score
	if params.score:
		match_score = _scores[params.score]
	else:
		match_score = {"value": params.value, "created": _GotmUtility.get_iso_from_unix_time(OS.get_unix_time(), OS.get_ticks_msec() % 1000), "path": _GotmUtility.create_resource_path("scores")}
	if not match_score:
			return 0
	var rank = 1
	for score in scores:
		if ScoreSearchPredicate.is_greater_than(match_score, score):
			return rank
		rank += 1
	return rank

static func _match_props(subset, superset) -> bool:
	if typeof(subset) != typeof(superset):
		return false
	if subset is Dictionary:
		if subset.size() > superset.size():
			return false
		for key in subset.keys():
			if not _match_props(subset[key], superset[key]):
				return false
		return true
	if subset is Array:
		if subset.size() > superset.size():
			return false
		for i in range(0, subset.size()):
			if not _match_props(subset[i], superset[i]):
				return false
		return true
	return subset == superset

static func _get_range_from_period(period: String) -> Array:
	match period:
		"":
			return [null, null]
		"year", "month", "week", "day":
			return [_GotmUtility.get_iso_from_unix_time(GotmPeriod.sliding(period).to_unix_time()), null]
	
	if period.begins_with("week"):
		var week_number = int(period.substr("week".length(), period.length() - "week".length()))
		if week_number > 0:
			var unix_time = 60 * 60 * 24 * 7 * week_number
			return [_GotmUtility.get_iso_from_unix_time(unix_time - 60 * 60 * 24 * 3), _GotmUtility.get_iso_from_unix_time(unix_time + 60 * 60 * 24 * 4 - 1)]

	var parts = period.split("-")
	var year = parts[0] if parts.size() >= 1 else ""
	var month = parts[1] if parts.size() >= 2 else ""
	var day = parts[2] if parts.size() >= 3 else ""
	var granularity: String = ""
	if day:
		granularity = GotmPeriod.TimeGranularity.DAY
		year = int(year)
		month = int(month)
		day = int(day)
	elif month: 
		granularity = GotmPeriod.TimeGranularity.MONTH
		year = int(year)
		month = int(month)
		day = 1
	elif year:
		granularity = GotmPeriod.TimeGranularity.YEAR
		year = int(year)
		month = 1
		day = 1
	if granularity:
		var start = OS.get_unix_time_from_datetime({"year": year, "month": month, "day": day, "hour": 0, "minute": 0, "second": 0})
		var end_datetime = {"year": year, "month": month, "day": day, "hour": 0, "minute": 0, "second": 0}
		end_datetime[granularity] += 1
		var end = OS.get_unix_time_from_datetime(end_datetime) - 1
		return [_GotmUtility.get_iso_from_unix_time(start), _GotmUtility.get_iso_from_unix_time(end)]

	return [null, null]

static func _match_score(score, params) -> bool:
	if params.name != score.name or params.author and params.author != score.author:
		return false
	if params.props and not _match_props(params.props, score.properties):
		return false
	if params.period:
		var period_range = _get_range_from_period(params.period)
		var start = period_range[0]
		var end = period_range[1]
		if start and score.created < start or end and score.created > end:
			return false
	return true

class ScoreSearchPredicate:
	static func is_less_than(a, b) -> bool:
		return a.value < b.value or (a.value == b.value and (a.created < b.created or a.created == b.created and a.path < b.path))

	static func is_greater_than(a, b) -> bool:
		return a.value > b.value or (a.value == b.value and (a.created > b.created or a.created == b.created and a.path > b.path))

static func _fetch_by_score_sort(params) -> Array:
	var matches := []
	var scores_per_author := {}
	for score in _scores:
		if _match_score(score, params):
			if params.is_unique:
				var existing_score = scores_per_author[score.author]
				if not existing_score or score.created > existing_score.created:
					scores_per_author[score.author] = score
			else:
				matches.append(score)
	if params.is_unique:
		matches = scores_per_author.values()
	matches.sort_custom(ScoreSearchPredicate, "is_greater_than" if params.descending else "is_less_than")
	return matches