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

static func get_surrounding_scores(leaderboard, score_id_or_value) -> Dictionary:
	if score_id_or_value is String:
		var score_id = score_id_or_value
		var beforeSig := _GotmUtility.defer_signal(_GotmScore.list(leaderboard, score_id, true))
		var scoreSig = GotmScore.fetch(score_id)
		var afterSig := _GotmUtility.defer_signal(_GotmScore.list(leaderboard, score_id, false))
		var score = yield(scoreSig, "completed")
		if !score:
			return {"before": [], "score": null, "after": []}
		var before: Array = yield(beforeSig.get_yieldable(), "completed")
		var after: Array = yield(afterSig.get_yieldable(), "completed")
		before.invert()
		return {"before": before, "score": score, "after": after}
	elif score_id_or_value is float || score_id_or_value is int:
		var value = score_id_or_value
		var beforeSig = _GotmUtility.defer_signal(_GotmScore.list(leaderboard, value, true))
		var scores = yield(_GotmScore.list(leaderboard, value, false), "completed")
		var score = scores[0] if scores else null
		var after: Array = yield(_GotmScore.list(leaderboard, score.id, false), "completed") if score else []
		var before: Array = yield(beforeSig.get_yieldable(), "completed")
		before.invert()
		return {"before": before, "score": score, "after": after}
	return {"before": [], "score": null, "after": []}
