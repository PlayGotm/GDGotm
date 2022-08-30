class_name _GotmLeaderboard
#warnings-disable

static func get_surrounding_scores(leaderboard, center) -> Dictionary:
	if center is int:
		center = float(center)
	return yield(_get_surrounding_scores(leaderboard, center), "completed")

static func get_surrounding_scores_by_rank(leaderboard, center) -> Dictionary:
	if center is float:
		center = int(center)
	return yield(_get_surrounding_scores(leaderboard, center), "completed")

static func _get_surrounding_scores(leaderboard, center) -> Dictionary:
	center = _coerce_id(center)
	center = _GotmUtility.clean_for_json(center)
	if center && center is String:
		var score_id = center
		var beforeSig := _GotmUtility.defer_signal(_GotmScore._list(leaderboard, score_id, true))
		var scoreSig = GotmScore.fetch(score_id)
		var afterSig := _GotmUtility.defer_signal(_GotmScore._list(leaderboard, score_id, false))
		var score = yield(scoreSig, "completed")
		if !score:
			return {"before": [], "score": null, "after": []}
		var before: Array = yield(beforeSig.get_yieldable(), "completed")
		var after: Array = yield(afterSig.get_yieldable(), "completed")
		before.invert()
		return {"before": before, "score": score, "after": after}
	
	var scores: Array = []
	if center is float:
		scores = yield(_GotmScore._list(leaderboard, center, false, 1), "completed")
	elif (center is int && center > 1):
		scores = yield(_GotmScore._list(leaderboard, center - 1, false, 1), "completed")
	else:
		scores = yield(_GotmScore._list(leaderboard, null, false, 1), "completed")
	
	var score = scores[0] if scores else null
	var beforeSig := _GotmUtility.defer_signal(_GotmScore._list(leaderboard, score, true))
	var after: Array = yield(_GotmScore._list(leaderboard, score, false), "completed") if score else []
	var before: Array = yield(beforeSig.get_yieldable(), "completed")
	before.invert()
	return {"before": before, "score": score, "after": after}



	
static func _coerce_id(resource_or_id):
	return _GotmUtility.coerce_resource_id(resource_or_id, "scores")