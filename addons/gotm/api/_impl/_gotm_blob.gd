class_name _GotmBlob

enum Implementation { GOTM_STORE, GOTM_BLOB_LOCAL }


static func _coerce_id(resource_or_id) -> String:
	var id = _GotmUtility.coerce_resource_id(resource_or_id, "blobs")
	if !(id is String):
		return ""
	return id


static func get_size(blob_id: String) -> int:
	var id := _coerce_id(blob_id)
	if id.is_empty():
		return 0
	var data: Dictionary
	if get_implementation(id) == Implementation.GOTM_BLOB_LOCAL:
		data = await _GotmBlobLocal.fetch(id)
	else:
		data = await _GotmStore.fetch(id)
	if !data.has("size"):
		return 0
	return int(data["size"])


# TODO: Validate changes from 3.X, old code didnt make sense to me since "data" is type Dictionary from fetch functions, but cannot be used in 'bytes_to_var_with_objects'
static func get_data(id: String, type: String = "bytes"):
	if id.is_empty() || type.is_empty():
		return null

	var binary_data: PackedByteArray
	if get_implementation(id) == Implementation.GOTM_BLOB_LOCAL:
		binary_data = await _GotmBlobLocal.fetch_blob(id)
	else:
		binary_data = await _GotmStore.fetch_blob(_Gotm.api_storage_origin + "/" + id)
	if binary_data.is_empty():
		return null

	match type:
		"node":
			var node = bytes_to_var_with_objects(binary_data)
			if !(node is Object):
				return null
			return node.instantiate()
		"variant":
			return bytes_to_var_with_objects(binary_data)
		_:
			return binary_data


static func get_implementation(id = null) -> Implementation:
	if !_LocalStore.fetch(id).is_empty() || !_Gotm.has_global_api():
		return Implementation.GOTM_BLOB_LOCAL
	return Implementation.GOTM_STORE
