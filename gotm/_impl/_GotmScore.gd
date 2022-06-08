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

# There are three implementations, development, http and gotm 
# We could intercept fetches, and fix backwards incompatibility that way.
# Probably need a plugin version indicator somewhere.

static func get_implementation():
	if not Gotm.is_live() and not Gotm.get_config().experimentalForceLiveScoresApi:
		return _GotmScoreDevelopment
	return _GotmStore

static func create(score, name: String, value: float, properties: Dictionary = {}):
	var data = yield(get_implementation().create("scores", {"name": name, "value": value, "properties": properties}), "completed")
	return _GotmUtility.copy(data, score)

static func update(score, value = null, properties = null):
	var new_score = yield(get_implementation().update(score.id, _GotmUtility.delete_null({"value": value, "properties": properties})), "completed")
	if not new_score:
		return
	if value != null:
		score.value = new_score.value
	if properties != null:
		score.properties = new_score.properties
	return score

static func delete(score) -> void:
	yield(get_implementation().delete(score.id), "completed")
