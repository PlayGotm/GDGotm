class_name _LocalStore


static func create(data: Dictionary) -> Dictionary:
	_get_store(data.path)[data.path] = data
	_write_store(data.path)
	return data


static func delete(path: String) -> bool:
	if path.is_empty():
		return false
	var result := _get_store(path).erase(path)
	_write_store(path)
	return result


static func fetch(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var fetched = _get_store(path).get(path)
	if fetched == null:
		return {}
	return _get_store(path).get(path)


static func get_all(path_or_api: String) -> Array:
	if path_or_api.is_empty():
		return []
	return _get_store(path_or_api).values()


static func _get_store(path_or_api: String) -> Dictionary:
	if path_or_api.is_empty():
		return {}
	var api = path_or_api.split("/")[0]
	var existing = _global.get(api)
	if existing is Dictionary:
		return existing

	var content := _GotmUtility.read_file(_Gotm.get_local_path(api + ".json"))
	if !content.is_empty():
		_global[api] = JSON.parse_string(content)
		if _global[api] == null:
			_global[api] = {}
	else:
		_global[api] = {}
	return _global[api]


static func update(path: String, data: Dictionary) -> Dictionary:
	var value := fetch(path)
	if value.is_empty() || data.is_empty():
		return value
	for key in data:
		value[key] = data[key]
	_write_store(path)
	return value


static func _write_store(path_or_api: String) -> void:
	var api := path_or_api.split("/")[0]
	_GotmUtility.write_file(_Gotm.get_local_path(api + ".json"), JSON.stringify(_get_store(api)))


static var _global := {}