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
	if !_Gotm.is_global_api("contents") || _LocalStore.fetch(id):
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
static func create(data = PoolByteArray(), properties: Dictionary = {}, key: String = "", name: String = "", is_private: bool = false, is_local: bool = false):
	properties = _GotmUtility.clean_for_json(properties)
	var implementation = _GotmContentLocal if is_local || is_private && yield(is_guest(), "completed") else get_implementation()
	if key && yield(get_by_key(key), "completed"):
		return
	var content = yield(implementation.create("contents", {"props": properties, "key": key, "name": name, "private": is_private}), "completed")
	content = _format(content, _Gotm.create_instance("GotmContent"))
	if data != null:
		return yield(update(content, data), "completed")
	_clear_cache()
	return content

# Update this score.
# Null is ignored.
static func update(content_or_id, data = null, properties = null, key = null, name = null):
	var id = _coerce_id(content_or_id)
	if !id:
		return
	if key:
		var existing = yield(get_by_key(key), "completed")
		if existing && existing.id != id:
			return
	properties = _GotmUtility.clean_for_json(properties)
	var body = _GotmUtility.delete_null({
		"props": properties,
		"key": key,
		"name": name,
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
	var id = _coerce_id(content_or_id)
	yield(get_implementation(id).delete(id), "completed")
	_clear_cache()

# Get an existing score.
static func fetch(content_or_id):
	var id = _coerce_id(content_or_id)
	var data = yield(get_implementation(id).fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmContent"))

static func get_by_key(key: String):
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project || !key:
		return
	var local_content = _GotmContentLocal.get_by_key_sync(key)
	if local_content:
		return _format(local_content[0], _Gotm.create_instance("GotmContent"))
	var data_list = yield(get_implementation().list("contents", "byKey", {"target": project, "key": key}), "completed")
	if !data_list:
		return
	return _format(data_list[0], _Gotm.create_instance("GotmContent"))

static func _format_filter(filter):
	filter = filter.duplicate(true)
	if filter.prop == "user_id":
		filter.prop = "author"
	elif filter.prop == "name_part":
		filter.prop = "namePart"
	elif filter.prop == "blob_id":
		filter.prop = "data"
	elif filter.prop == "is_private":
		filter.prop = "private"
	elif filter.prop.begins_with("properties"):
		filter.prop = "props" + filter.prop.substr("properties".length(), filter.prop.length())
	elif filter.prop == "is_local":
		return
	elif filter.prop == "updated" || filter.prop == "created":
		for key in ["min", "max", "value"]:
			var value = filter.get("key")
			if value is int || value is float:
				filter[key] = _GotmUtility.get_iso_from_unix_time(filter[key])
	return filter


static func list(query: GotmQuery, after_content_or_id = null) -> Array:
	query = _GotmQuery.get_formatted(query)
	var after_id = _coerce_id(after_content_or_id)
	var project = yield(_GotmUtility.get_yieldable(_get_project()), "completed")
	if !project:
		return []
	var is_local := false
	var is_private := false
	var filters := []
	var sorts := []
	for filter in query.filters:
		if filter.prop == "is_local":
			is_local = !!filter.get("value")
		elif filter.prop == "is_private":
			is_private = !!filter.get("value")
		filter = _format_filter(filter)
		if filter:
			filters.append(filter)
	for sort in query.sorts:
		sort = _format_filter(sort)
		if sort:
			sorts.append(sort)
	if is_private:
		var auth = get_auth_implementation().get_auth()
		if auth.is_guest:
			is_local = true
			filters.append({"prop": "author", "value": _GotmAuthLocal.get_user()})
		else:
			filters.append({"prop": "author", "value": auth.owner})
	var params := {"filters": filters, "sorts": sorts, "target": project, "after": after_id}
	_GotmUtility.delete_empty(params)
	var implementation = _GotmContentLocal if is_local else get_implementation(after_id)
	var data_list = yield(implementation.list("contents", "byContentSort", params, is_private), "completed")
	if !data_list:
		return []

	var contents = []
	for data in data_list:
		contents.append(_format(data, _Gotm.create_instance("GotmContent")))
	return contents

static func update_by_key(key: String, data = null, properties = null, new_key = null, name = null):
	var content = yield(get_by_key(key), "completed")
	return yield(update(content, data, properties, new_key, name), "completed")
	
static func delete_by_key(key: String) -> void:
	var content = yield(get_by_key(key), "completed")
	yield(delete(content), "completed")

static func _clear_cache():
	get_implementation().clear_cache("contents")
	get_implementation().clear_cache("blobs")
	get_implementation().clear_cache(_Gotm.get_global().storageApiEndpoint)
	get_implementation().clear_cache("marks")

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
	content.is_private = data.private
	content.updated = data.updated
	content.created = data.created
	content.is_local = !!_LocalStore.fetch(data.path)
	return content
	
	
static func _coerce_id(resource_or_id):
	return _GotmUtility.coerce_resource_id(resource_or_id, "contents")