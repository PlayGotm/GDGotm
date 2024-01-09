class_name _GotmLeaderboard


static func _coerce_id(resource_or_id) -> String:
	var id = _GotmUtility.coerce_resource_id(resource_or_id, "scores")
	if !(id is String):
		return ""
	return id


static func _get_surrounding_scores(leaderboard: GotmLeaderboard, center) -> GotmLeaderboard.SurroundingScores:
	if !is_valid(leaderboard):
		return null

	if center is GotmScore || center is String:
		var id := _coerce_id(center)
		if id.is_empty():
			return null

		var score := await GotmScore.fetch(id)
		if !score:
			return null

		var before := await _GotmScore._list(leaderboard, id, true)
		before.reverse()
		var after := await _GotmScore._list(leaderboard, id, false)
		var surrounding_scores := GotmLeaderboard.SurroundingScores.new()
		surrounding_scores.before = before
		surrounding_scores.score = score
		surrounding_scores.after = after
		return surrounding_scores

	var epsilon := 1e-10
	var center_score: GotmScore
	# Attempt to get the nearest GotmScore from center value or rank
	# TODO: Validate changes, changed to a more true center score. Also fixes bug if there is only one score on leaderboard
	if center is float:
		var descending_score := await _GotmScore._list(leaderboard, center + epsilon, false, 1)
		var ascensing_score := await _GotmScore._list(leaderboard, center - epsilon, true, 1)
		if descending_score.is_empty() && ascensing_score.is_empty(): # There are no scores
			return GotmLeaderboard.SurroundingScores.new()
		elif descending_score.is_empty():
			center_score = ascensing_score[0]
		elif ascensing_score.is_empty():
			center_score = descending_score[0]
		elif abs(center - descending_score[0].value) <= abs(center - ascensing_score[0].value):
			center_score = descending_score[0]
		else:
			center_score = ascensing_score[0]
	# Attempt to get rank
	elif center is int && center > 1:
		var scores := await _GotmScore._list(leaderboard, center - 1, false, 1)
		if scores.is_empty():
			push_error("GotmLeaderboard: Could not get rank.")
			return GotmLeaderboard.SurroundingScores.new()
		center_score = scores[0]
	# Attempt to get the score with Rank 1
	else:
		var scores := await _GotmScore._list(leaderboard, null, false, 1)
		if scores.is_empty():
			push_error("GotmLeaderboard: Could not get rank. Is the leaderboard empty?")
			return GotmLeaderboard.SurroundingScores.new()
		center_score = scores[0]

	var before := await _GotmScore._list(leaderboard, center_score, true)
	before.reverse()
	var after := await _GotmScore._list(leaderboard, center_score, false)
	var surrounding_scores := GotmLeaderboard.SurroundingScores.new()
	surrounding_scores.before = before
	surrounding_scores.score = center_score
	surrounding_scores.after = after
	return surrounding_scores


static func get_surrounding_scores(leaderboard: GotmLeaderboard, center) -> GotmLeaderboard.SurroundingScores:
	if !(center is int || center is float || center is String || center is GotmScore):
		push_error("GotmLeaderboard: Expected an int, float, GotmScore or GotmScore.id string.")
		return null

	if !is_valid(leaderboard):
		return null

	if center is int:
		center = float(center)
	return await _get_surrounding_scores(leaderboard, center)


static func get_surrounding_scores_by_rank(leaderboard: GotmLeaderboard, center) -> GotmLeaderboard.SurroundingScores:
	if !(center is int || center is float || center is String || center is GotmScore):
		push_error("GotmLeaderboard: Expected an int, float, GotmScore or GotmScore.id string.")
		return null

	if !is_valid(leaderboard):
		return null

	if center is float:
		center = int(center)
	return await _get_surrounding_scores(leaderboard, center)


static func is_valid(leaderboaard: GotmLeaderboard) -> bool:
	if leaderboaard.name.is_empty():
		push_error("GotmLeaderboard: Leaderboard must have a name.")
		return false
	return true
