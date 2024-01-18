class_name _GotmBlobLocal


static func create(api: String, body: Dictionary) -> Dictionary:
	api = api.split("/")[0]
	var data = body.data
	if !(data is PackedByteArray) || data == PackedByteArray():
		return {}

	var blob = {
		"path": _GotmUtility.create_resource_path(api),
		"author": _GotmAuthLocal.get_user(),
		"target": body.target,
		"size": data.size()
	}
	_GotmUtility.write_file(_Gotm.get_local_path(blob.path), data)
	return _format(_LocalStore.create(blob))


static func delete_sync(path: String) -> bool:
	var blob := _LocalStore.fetch(path)
	if blob.is_empty():
		return false
	var result := _LocalStore.delete(path)
	_GotmUtility.write_file(_Gotm.get_local_path(blob.path), null)
	return result


# TODO: Validate changes from 3.X, old code didnt make sense to me since there was a non-dictionary return as PackedByteArray when returning the 'read_file' line
static func fetch(path: String, _query: String = "", _params: Dictionary = {}, _authenticate: bool = false) -> Dictionary:
	var blob := _LocalStore.fetch(path)
	if blob.is_empty():
		return {}
	return _format(blob)


static func fetch_blob(path: String) -> PackedByteArray:
	var blob := _LocalStore.fetch(path)
	if blob.is_empty():
		return PackedByteArray()
	return _GotmUtility.read_file_as_binary(_Gotm.get_local_path(blob.path))


static func _format(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	data = _GotmUtility.copy(data, {})
	return data
