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

class_name GotmContent
#warnings-disable


# BETA FEATURE
# A score entry used for leaderboards.
# To fetch ranks and scores, see the GotmLeaderboard class.

##############################################################
# PROPERTIES
##############################################################




# Unique identifier of the score.
var id: String

# Unique identifier of the user who owns the score.
# Is automatically set to the current user's id when creating the score.
# If the score is created while the game runs outside gotm.io, this user will 
# always be an unregistered user with no display name.
# If the score is created while the game is running on Gotm with a signed in
# user, you can get their display name via GotmUser.fetch.
var user_id: String

# Optional unique key.
var key: String

# Optional name searchable with partial search.
var name: String

# Download
var blob_id: String

# Optional metadata to attach to the score entry, 
# for example {level: "desert1", difficulty: "hard"}.
# When fetching ranks and scores with GotmLeaderboard, you can optionally 
# filter with these properties. 
var properties: Dictionary

var private: bool

# UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(score.created / 1000) to convert to date.
var updated: int

# UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(score.created / 1000) to convert to date.
var created: int


##############################################################
# METHODS
##############################################################

# Create a score entry for the current user.
# Scores can be fetched via a GotmLeaderboard instance.
# See PROPERTIES above for descriptions of the arguments.
static func create(data = null, properties: Dictionary = {}, key: String = "", name: String = "", private: bool = false)  -> GotmContent:
	return yield(_GotmContent.create(data, properties, key, name, private), "completed")

# Update this score.
# Null is ignored.
static func update(content_or_id, data = null, properties = null, key = null, name = null, private = null) -> GotmContent:
	return yield(_GotmContent.update(content_or_id, data, properties, key, name, private), "completed")

# Delete this score.
static func delete(content_or_id) -> void:
	return yield(_GotmContent.delete(content_or_id), "completed")

# Get an existing score.
static func fetch(content_or_id) -> GotmContent:
	return yield(_GotmContent.fetch(content_or_id), "completed")

static func get_by_key(key: String) -> GotmContent:
	return yield(_GotmContent.get_by_key(key), "completed")

static func get_by_directory(directory: String) -> void:
	return yield(_GotmContent.get_by_directory(directory), "completed")

static func update_by_key(key: String, data = null, properties = null, key = null, name = null, private = null) -> GotmContent:
	return yield(_GotmContent.update_by_key(key, data, properties, key, name, private), "completed")
	
static func delete_by_key(key: String) -> void:
	return yield(_GotmContent.delete_by_key(key), "completed")




class QueryProperty:
	const ID = "id"
	const USER_ID = "user_id"
	const KEY = "key"
	const DIRECTORY = "directory" # Derived from key
	const EXTENSION = "extension" # Derived from key
	const NAME = "name"
	const NAME_SEARCH = "name_search"
	const PROPERTIES = "properties"
	const PRIVATE = "private"
	const UPDATED = "updated"
	const CREATED = "created"
	const RATING = "rating"
	const SIZE = "size"
	
	static func get_custom_property(path: String) -> String:
		return PROPERTIES + path if path.begins_with("/") else PROPERTIES + "/" + path

# directory to list contents directly in that directory. To list contents recursively, use sort query.
#static func list(after_content_or_id = null, name_search = null, query: GotmQuery = GotmQuery.new()) -> Array:
#	return []


