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
# A GotmContent is a piece of data that is used to affect your game's
# content dynamically, such as player-generated content, game saves,
# downloadable packs/mods or remote configuration.

##############################################################
# PROPERTIES
##############################################################

# Unique immutable identifier.
var id: String

# Unique identifier of the user who owns the content.
# Is automatically set to the current user's id when creating the content.
# If the content is created while the game runs outside gotm.io, this user will 
# always be an unregistered user with no display name.
# If the content is created while the game is running on Gotm with a signed in
# user, you can get their display name via GotmUser.fetch.
var user_id: String

# Optional unique key.
var key: String

# Optional name searchable with partial search.
var name: String

# Id of this content's data. Use GotmBlob.fetch_data(content.blob_id) to get the data as a PoolByteArray.
var blob_id: String

# Optional metadata to attach to the score entry, 
# for example {level: "desert1", difficulty: "hard"}.
# When fetching ranks and scores with GotmLeaderboard, you can optionally 
# filter with these properties. 
var properties: Dictionary

var private: bool

# Is true if this content was created with GotmContent.create_local and is only stored locally on the user's device.
var local: bool

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
static func create(data = null, key: String = "", properties: Dictionary = {}, name: String = "", private: bool = false)  -> GotmContent:
	return yield(_GotmContent.create(data, properties, key, name, private), "completed")

static func create_local(data = null, key: String = "", properties: Dictionary = {}, name: String = "", private: bool = false)  -> GotmContent:
	return yield(_GotmContent.create(data, properties, key, name, private, true), "completed")

# Update this score.
# Null is ignored.
static func update(content_or_id, data = null, key = null, properties = null, name = null) -> GotmContent:
	return yield(_GotmContent.update(content_or_id, data, properties, key, name, private), "completed")

# Delete this score.
static func delete(content_or_id) -> void:
	return yield(_GotmContent.delete(content_or_id), "completed")

# Get an existing score.
static func fetch(content_or_id) -> GotmContent:
	return yield(_GotmContent.fetch(content_or_id), "completed")

static func get_by_key(key: String) -> GotmContent:
	return yield(_GotmContent.get_by_key(key), "completed")

static func get_by_directory(directory: String, after_content_or_id = null) -> Array:
	return yield(_GotmContent.get_by_directory(directory, false, after_content_or_id), "completed")

static func get_local_by_directory(directory: String, after_content_or_id = null) -> Array:
	return yield(_GotmContent.get_by_directory(directory, true, after_content_or_id), "completed")
	

static func update_by_key(key: String, data = null, key = null, properties = null, name = null) -> GotmContent:
	return yield(_GotmContent.update_by_key(key, data, properties, key, name, private), "completed")
	
static func delete_by_key(key: String) -> void:
	return yield(_GotmContent.delete_by_key(key), "completed")




# directory to list contents directly in that directory. To list contents recursively, use sort query.
# sort by rating, size
# filter by directory, extension, partial_name
#static func list(query: GotmQuery = GotmQuery.new(), after_content_or_id = null) -> Array:
#	return []

