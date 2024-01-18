class_name _GotmContent

enum AuthImplementation { GOTM_AUTH, GOTM_AUTH_LOCAL }
enum BlobImplementation { GOTM_STORE, GOTM_BLOB_LOCAL }
enum Implementation { GOTM_STORE, GOTM_CONTENT_LOCAL }


static func _clear_cache() -> void:
	if get_implementation() == Implementation.GOTM_STORE:
		_GotmStore.clear_cache("contents")
		_GotmStore.clear_cache("blobs")
		_GotmStore.clear_cache("marks")
		_GotmStore.clear_cache(_Gotm.api_storage_origin)


static func _coerce_id(resource_or_id) -> String:
	var id = _GotmUtility.coerce_resource_id(resource_or_id, "contents")
	if !(id is String):
		return ""
	return id


static func _coerce_ids(contents_or_ids: Array) -> Array:
	if contents_or_ids.is_empty():
		return []
	var ids := []
	for content_or_id in contents_or_ids:
		var id := _coerce_id(content_or_id)
		if !id.is_empty():
			ids.append(id)
	return ids


static func create(data = PackedByteArray(), properties: Dictionary = {},
		key: String = "", name: String = "", parent_ids: Array = [],
		is_private: bool = false, is_local: bool = false) -> GotmContent:

	if !key.is_empty() && await _get_by_key(key):
		push_error("[GotmContent] Cannot create content with key %s. Content with key already exists." % key)
		return null

	properties = _GotmUtility.clean_for_json(properties)
	parent_ids = _coerce_ids(parent_ids)
	var content_dict: Dictionary

	if is_local || get_implementation() == Implementation.GOTM_CONTENT_LOCAL || (is_private && await is_guest()):
		content_dict = await _GotmContentLocal.create("contents",
				{"props": properties, "key": key, "name": name,
				"private": is_private, "parents": parent_ids})
	else:
		content_dict = await _GotmStore.create("contents",
				{"props": properties, "key": key, "name": name,
				"private": is_private, "parents": parent_ids})
	var content := await _format(content_dict, GotmContent.new())
	if data != null:
		return await update(content, data)
	_clear_cache()
	return content


static func delete(content_or_id) -> bool:
	if !(content_or_id is GotmContent || content_or_id is String):
		push_error("[GotmContent] Expected a GotmContent or GotmContent.id string.")
		return false

	var id := _coerce_id(content_or_id)
	var result := false
	if get_implementation(id) == Implementation.GOTM_CONTENT_LOCAL:
		result = await _GotmContentLocal.delete(id)
	else:
		result = await _GotmStore.delete(id)
	_clear_cache()
	return result


static func delete_by_key(key: String) -> bool:
	var content = await _get_by_key(key)
	if content == null:
		push_error("[GotmContent] Cannot delete. Content with key (%s) not found." % key)
		return false
	return await delete(content)


static func fetch(content_or_id, type: String = ""):
	if !(content_or_id is GotmContent || content_or_id is String):
		push_error("[GotmContent] Expected a GotmContent or GotmContent.id string.")
		return null

	if type == "properties" && content_or_id is Object && content_or_id.has("properties"):
		return content_or_id.properties

	var id := _coerce_id(content_or_id)
	var data: Dictionary
	if get_implementation(id) == Implementation.GOTM_CONTENT_LOCAL:
		data = await _GotmContentLocal.fetch(id)
	else:
		data = await _GotmStore.fetch(id)
	if !data.is_empty() && !type.is_empty():
		if type == "properties":
			return data.props
		var content_data = await _GotmBlob.get_data(data.data, type)
		if type == "node" && content_data == null:
			push_error("[GotmContent] Cannot find node with id: %s. Does content extend Node?" % id)
			return null
		if type == "variant" && content_data == null:
			push_error("[GotmContent] Cannot find variant with id: %s. Note, variant cannot be a PackedByteArray or null." % id)
			return null
		return await content_data
	var content := await _format(data, GotmContent.new())
	if !content:
		push_error("[GotmContent] Cannot fetch content with id: ", id)
		return null
	return content


static func _format(data: Dictionary, content: GotmContent) -> GotmContent:
	if data.is_empty() || !content:
		return null

	content.id = data.path
	content.user_id = data.author
	content.key = data.key
	content.name = data.name
	content.properties = data.props if data.get("props") else {}
	content.is_private = data.private
	content.updated = data.updated
	content.created = data.created
	content.parent_ids = data.parents
	content.is_local = !_LocalStore.fetch(data.path).is_empty()
	if data.has("data"):
		content.size = await _GotmBlob.get_size(data.data)
	return content


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
	elif filter.prop == "parent_ids":
		filter.prop = "parents"
		if filter.has("value"):
			if filter.value is Array:
				filter.value = _coerce_ids(filter.value)
			else:
				filter.value = [_coerce_id(filter.value)]
	return filter


static func get_auth_implementation() -> AuthImplementation:
	if get_implementation() == Implementation.GOTM_CONTENT_LOCAL:
		return AuthImplementation.GOTM_AUTH_LOCAL
	return AuthImplementation.GOTM_AUTH


static func get_blob_implementation(id = null) -> BlobImplementation:
	if get_implementation(id) == Implementation.GOTM_CONTENT_LOCAL:
		return BlobImplementation.GOTM_BLOB_LOCAL
	return BlobImplementation.GOTM_STORE


static func _get_by_key(key: String, type: String = ""):
	if key.is_empty():
		push_error("[GotmContent] Cannot find content with empty key.")
		return null

	var project := await _get_project()
	if project.is_empty():
		push_error("[GotmContent] Project is not setup correctly.")
		return null

	var data_list := _GotmContentLocal.get_by_key_sync(key)
	if data_list.is_empty():
		if get_implementation() == Implementation.GOTM_CONTENT_LOCAL:
			data_list = await _GotmContentLocal.list("byKey", {"target": project, "key": key})
		else:
			data_list = await _GotmStore.list("contents", "byKey", {"target": project, "key": key})
	if data_list.is_empty():
		return null

	var data = data_list[0]
	if data && !type.is_empty():
		if type == "properties":
			return data.props
		return await _GotmBlob.get_data(data.data, type)
	return await _format(data, GotmContent.new())


static func get_by_key(key: String, type: String = ""):
	var result = await _get_by_key(key, type)
	if result == null && type == "node":
		push_error("[GotmContent] Cannot find node with key: %s. Does content extend Node?" % key)
		return null

	if result == null && type == "variant":
		push_error("[GotmContent] Cannot find variant with key: %s. Note, variant cannot be a PackedByteArray or null." % key)
		return null

	if result == null:
		push_error("[GotmContent] Cannot find with key: ", key)
		if type == "properties":
			return {}
	return result


static func get_implementation(id: String = "") -> Implementation:
	if !_Gotm.is_global_api("contents") || !_LocalStore.fetch(id).is_empty():
		return Implementation.GOTM_CONTENT_LOCAL
	return Implementation.GOTM_STORE


static func _get_project() -> String:
	var auth
	var local := true
	if get_auth_implementation() == AuthImplementation.GOTM_AUTH:
		auth = _GotmAuth.get_auth()
		local = false
	else:
		auth = _GotmAuthLocal.get_auth()
	if !auth:
		if local:
			auth = await _GotmAuthLocal.get_auth_async()
		else:
			auth = await _GotmAuth.get_auth_async()
	if !auth:
		return ""
	return auth.project


static func is_guest() -> bool:
	var auth
	if get_auth_implementation() == AuthImplementation.GOTM_AUTH:
		auth = await _GotmAuth.get_auth_async()
	else:
		auth = await _GotmAuthLocal.get_auth_async()
	if !auth:
		return true
	return auth.is_guest


static func list(query: GotmQuery, after_content_or_id = null) -> Array:
	query = _GotmQuery.get_formatted(query)
	var after_id := ""
	if after_content_or_id is GotmContent || after_content_or_id is String:
		after_id = _coerce_id(after_content_or_id)
	var project := await _get_project()
	if project.is_empty():
		return []
	var is_local := false
	var is_private := false
	var filters := []
	var sorts := []
	for filter in query.filters:
		if filter.prop == "is_local":
			is_local = filter.get("value") as bool
		elif filter.prop == "is_private":
			is_private = filter.get("value") as bool
		filter = _format_filter(filter)
		if filter:
			filters.append(filter)
	for sort in query.sorts:
		sort = _format_filter(sort)
		if sort:
			sorts.append(sort)
	if is_private:
		var auth
		if get_auth_implementation() == AuthImplementation.GOTM_AUTH:
			auth = _GotmAuth.get_auth()
		else:
			auth = _GotmAuthLocal.get_auth()
		if auth.is_guest:
			is_local = true
			filters.append({"prop": "author", "value": _GotmAuthLocal.get_user()})
		else:
			filters.append({"prop": "author", "value": auth.owner})
	var params := {"filters": filters, "sorts": sorts, "target": project, "after": after_id}
	_GotmUtility.delete_empty(params)
	var data_list := []
	if is_local || get_implementation(after_id) == Implementation.GOTM_CONTENT_LOCAL:
		data_list = await _GotmContentLocal.list("byContentSort", params)
	else:
		data_list = await _GotmStore.list("contents", "byContentSort", params, is_private)
	if data_list.is_empty():
		return []

	var contents = []
	for data in data_list:
		contents.append(await _format(data, GotmContent.new()))
	return contents


static func update(content_or_id, data = null, properties = null, key = null, name = null) -> GotmContent:
	if !(content_or_id is GotmContent || content_or_id is String):
		push_error("[GotmContent] Expected a GotmContent or GotmContent.id string.")
		return null

	var id := _coerce_id(content_or_id)
	if id.is_empty():
		return null
	if key:
		var existing = await _get_by_key(key)
		if existing && existing.id != id:
			return null
	properties = _GotmUtility.clean_for_json(properties)
	var body = _GotmUtility.delete_null({
		"props": properties,
		"key": key,
		"name": name,
	})
	var ignore_blob := true
	if data != null:
		if data is Node:
			var packed_scene := PackedScene.new()
			packed_scene.pack(data)
			data = packed_scene
		if !(data is PackedByteArray):
			data = var_to_bytes_with_objects(data)
		var blob: Dictionary
		if get_blob_implementation(id) == BlobImplementation.GOTM_BLOB_LOCAL:
			blob = await _GotmBlobLocal.create("blobs/upload", {"target": id, "data": data})
		else:
			blob = await _GotmStore.create("blobs/upload", {"target": id, "data": data})
		if !blob.is_empty():
			body.data = blob.path
			ignore_blob = false
	var content: Dictionary
	if get_implementation(id) == Implementation.GOTM_CONTENT_LOCAL:
		if !ignore_blob:
			await _GotmContentLocal.delete_blob(id) # delete old blob content
		content = await _GotmContentLocal.update(id, body)
	else:
		content = await _GotmStore.update(id, body)
	if !content.is_empty():
		_clear_cache()
	return await _format(content, GotmContent.new())


static func update_by_key(key: String, data = null, properties = null, new_key = null, name = null) -> GotmContent:
	var content = await _get_by_key(key)
	if content == null:
		push_error("[GotmContent] Cannot find with key: ", key)
	return await update(content, data, properties, new_key, name)
