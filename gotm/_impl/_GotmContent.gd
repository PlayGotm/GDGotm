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


static func get_implementation(id = null):
	var config := _Gotm.get_config()
	if !_Gotm.is_global_feature(config.force_local_scores, config.beta_unsafe_force_global_scores) || _LocalStore.fetch(id):
		return _GotmContentLocal
	return _GotmStore

static func get_blob_implementation(id = null):
	if get_implementation(id) == _GotmContentLocal:
		return _GotmBlobLocal
	return _GotmStore

static func get_auth_implementation():
	if get_implementation() == _GotmContentLocal:
		return _GotmAuthLocal
	return _GotmAuth


static func is_guest():
	var auth = yield(get_auth_implementation().get_auth_async(), "completed")
	if !auth:
		return true
	return !!auth.is_guest


# Create a score entry for the current user.
# Scores can be fetched via a GotmLeaderboard instance.
# See PROPERTIES above for descriptions of the arguments.
static func create(data = PoolByteArray(), properties: Dictionary = {}, key: String = "", name: String = "", private: bool = false, is_local: bool = false):
	properties = _GotmUtility.clean_for_json(properties)
	var implementation = _GotmContentLocal if is_local || private && yield(is_guest(), "completed") else get_implementation()
	var content = yield(implementation.create("contents", {"props": properties, "key": key, "name": name, "private": private}), "completed")
	if data != null:
		return yield(update(content, data), "completed")
	_clear_cache()
	return _format(content, _Gotm.create_instance("GotmContent"))

# Update this score.
# Null is ignored.
static func update(content_or_id, data = null, properties = null, key = null, name = null):
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
		var blob = yield(get_blob_implementation(id).create("blobs/upload", {"target": id, "data": data}), "completed")
		if blob:
			body.data = blob.path
	var content = yield(get_implementation(id).update(id, body), "completed")
	if content:
		_clear_cache()
	return _format(content, _Gotm.create_instance("GotmContent"))

# Delete this score.
static func delete(content_or_id) -> void:
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	yield(get_implementation(id).delete(id), "completed")
	_clear_cache()

# Get an existing score.
static func fetch(content_or_id):
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	var data = yield(get_implementation(id).fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmContent"))

static func get_by_key(key: String):
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project || !key:
		return
	for content in _LocalStore.get_all("contents"):
		if content.key == key:
			return _format(content, _Gotm.create_instance("GotmContent"))
	var data_list = yield(get_implementation().list("contents", "byKey", {"target": project, "key": key}), "completed")
	if !data_list:
		return
	return _format(data_list[0], _Gotm.create_instance("GotmContent"))

static func get_by_directory(directory: String, local: bool = false, after_content_or_id = null):
	var query := GotmQuery.new()
	query.filter("directory", directory)
	if local:
		query.filter("local", true)
	return yield(list(query, after_content_or_id), "completed")

static func list(query: GotmQuery, after_content_or_id = null) -> Array:
	var after_id = _GotmUtility.coerce_resource_id(after_content_or_id)
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project:
		return
	var params := {}
	for key in query.filters:
		var new_key = key
		if key == "user_id":
			new_key = "author"
		elif key == "partial_name":
			new_key = "partialName"
		params[new_key] = query.filters[key]
	params.target = project
	params.sort = _GotmUtility.join(query.sorts, ",")
	if after_id:
		params.after = after_id
	var implementation = _GotmContentLocal if query.filters.local else get_implementation(after_id)
	var data_list = yield(implementation.list("contents", "byContentSort", params), "completed")
	if !data_list:
		return
		
	var contents = []
	for data in data_list:
		contents.append(_format(data, _Gotm.create_instance("GotmContent")))
	return contents

static func update_by_key(key: String, data = null, properties = null, key = null, name = null):
	var content = yield(get_by_key(key), "completed")
	return yield(update(content, data, properties, key, name), "completed")
	
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
	content.blob_id = data.data
	content.properties = data.props if data.get("props") else {}
	content.private = data.private
	content.updated = data.updated
	content.created = data.created
	content.local = !!_LocalStore.fetch(data.path)
	return content
	
	
