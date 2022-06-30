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
	center = _GotmScore._coerce_score_id(center)
	center = _GotmUtility.clean_for_json(center)
	if center is String:
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
