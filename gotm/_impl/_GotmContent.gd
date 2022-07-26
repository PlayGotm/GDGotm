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

class_name _GotmContent
#warnings-disable


static func get_implementation():
	var config := _Gotm.get_config()
	if !_Gotm.is_global_feature(config.forceLocalScores, config.betaUnsafeForceGlobalScores):
		return _GotmContentLocal
	return _GotmStore

static func get_blob_implementation():
	if get_implementation() == _GotmContentLocal:
		return _GotmBlobLocal
	return _GotmStore

static func get_auth_implementation():
	if get_implementation() == _GotmContentLocal:
		return _GotmAuthLocal
	return _GotmAuth


const CONTENT_OPTIONS = {
	"expand": {
		"data": {}
	}
}

# Create a score entry for the current user.
# Scores can be fetched via a GotmLeaderboard instance.
# See PROPERTIES above for descriptions of the arguments.
static func create(data = PoolByteArray(), properties: Dictionary = {}, key: String = "", name: String = "", private: bool = false):
	properties = _GotmUtility.clean_for_json(properties)
	var content = yield(get_implementation().create("contents", {"props": properties, "key": key, "name": name, "private": private}), "completed")
	if data != null:
		return yield(update(content, data), "completed")
	_clear_cache()
	return _format(content, _Gotm.create_instance("GotmContent"))

# Update this score.
# Null is ignored.
static func update(content_or_id, data = null, properties = null, key = null, name = null, private = null):
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	if !id:
		return
	properties = _GotmUtility.clean_for_json(properties)
	var body = _GotmUtility.delete_null({
		"props": properties,
		"key": key,
		"name": name,
		"private": private,
	})
	if data != null:
		var blob = yield(get_blob_implementation().create("blobs/upload", {"target": id, "data": data}), "completed")
		if blob:
			body.data = blob.path
	var content = yield(get_implementation().update(id, body, CONTENT_OPTIONS), "completed")
	if content:
		_clear_cache()
	return _format(content, _Gotm.create_instance("GotmContent"))

# Delete this score.
static func delete(content_or_id) -> void:
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	yield(get_implementation().delete(id), "completed")
	_clear_cache()

# Get an existing score.
static func fetch(content_or_id):
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	var data = yield(get_implementation().fetch(id, CONTENT_OPTIONS), "completed")
	return _format(data, _Gotm.create_instance("GotmContent"))

static func get_by_key(key: String):
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project || !key:
		return
	var data_list = yield(get_implementation().list("contents", "byKey", {"target": project, "key": key}, CONTENT_OPTIONS), "completed")
	if !data_list:
		return
	return _format(data_list[0], _Gotm.create_instance("GotmContent"))

static func get_by_directory(directory: String, after_content_or_id = null):
	var query := GotmQuery.new()
	query.filter(QueryProperty.DIRECTORY, directory)
	return yield(list(query, after_content_or_id), "completed")


static func list(query: GotmQuery, after_content_or_id = null) -> Array:
	var after_id = _GotmUtility.coerce_resource_id(after_content_or_id)
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project:
		return
	var params := {}
	for key in query.filters:
		var new_key = key
		if key == QueryProperty.USER_ID:
			new_key = "author"
		elif key == QueryProperty.NAME_SEARCH:
			new_key = "nameSearch"
		params[new_key] = query.filters[key]
	params.target = project
	params.sort = _GotmUtility.join(query.sorts, ",")
	if after_id:
		params.after = after_id
	var data_list = yield(get_implementation().list("contents", "byContentSort", params, CONTENT_OPTIONS), "completed")
	if !data_list:
		return
		
			
	var contents = []
	for data in data_list:
		contents.append(_format(data, _Gotm.create_instance("GotmContent")))
	return contents

static func update_by_key(key: String, data = null, properties = null, key = null, name = null, private = null):
	var content = yield(get_by_key(key), "completed")
	return yield(update(content, data, properties, key, name, private), "completed")
	
static func delete_by_key(key: String) -> void:
	var content = yield(get_by_key(key), "completed")
	yield(delete(content), "completed")

static func _clear_cache():
	pass # Not needed until we add queries

static func _get_project() -> String:
	var Auth = get_auth_implementation()
	var auth = Auth.get_auth()
	if !auth:
		auth = yield(Auth.get_auth_async(), "completed")
	if !auth:
		return
	return auth.project

static func _format(data, content):
	if !data || !content:
		return
	content.id = data.path
	content.user_id = data.author
	content.key = data.key
	content.name = data.name
	if content.get("data"):
		if !(content.data is Dictionary):
			push_warning("Expected content data to be expanded. " + to_json(get_stack()))
			content.data_url = ""
			content.data_type = ""
			content.data_size = 0
		else:
			content.data_url = content.data.downloadUrl
			content.data_type = content.data.format
			content.data_size = content.data.size
	content.properties = data.props if data.get("props") else {}
	content.updated = data.updated
	content.created = data.created
	return content
	
	
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
