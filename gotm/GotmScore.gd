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

class_name GotmScore
#warnings-disable

# BETA FEATURE
# A score entry used for leaderboards.
# To fetch ranks and scores, see the GotmLeaderboard class.

##############################################################
# PROPERTIES
##############################################################

# Unique immutable identifier.
var id: String

# Unique identifier of the user who owns the score.
# Is automatically set to the current user's id when creating the score.
# If the score is created while the game runs outside gotm.io, this user will 
# always be an unregistered user with no display name.
# If the score is created while the game is running on Gotm with a signed in
# user, you can get their display name via GotmUser.fetch.
var user_id: String

# A name that describes what this score represents and puts it in a category.
# For example, "bananas_collected".
var name: String

# A numeric representation of the score.
var value: float

# Optional metadata to attach to the score entry, 
# for example {level: "desert1", difficulty: "hard"}.
# When fetching ranks and scores with GotmLeaderboard, you can optionally 
# filter with these properties. 
var properties: Dictionary

# Is true if this score was created with GotmScore.create_local and is only stored locally on the user's device.
# Is useful for scores that do not need to be accessible to other devices, such as scores in an offline game.
var is_local: bool

# UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(score.created / 1000) to convert to date.
var created: int

##############################################################
# METHODS
##############################################################

# Create a score entry for the current user.
# Scores can be fetched via a GotmLeaderboard instance.
# See PROPERTIES above for descriptions of the arguments.
static func create(name: String, value: float, properties: Dictionary = {}) -> GotmScore:
	return yield(_GotmScore.create(name, value, properties, false), "completed")

static func create_local(name: String, value: float, properties: Dictionary = {}) -> GotmScore:
	return yield(_GotmScore.create(name, value, properties, true), "completed")

# Update an existing score.
# Null is ignored.
static func update(score_or_id, value = null, properties = null) -> GotmScore:
	return yield(_GotmScore.update(score_or_id, value, properties), "completed")

# Delete an existing  score.
static func delete(score_or_id) -> void:
	return yield(_GotmScore.delete(score_or_id), "completed")

# Get an existing score.
static func fetch(score_or_id) -> GotmScore:
	return yield(_GotmScore.fetch(score_or_id), "completed")
