class_name _LocalStore
#warnings-disable


const _global = {}

static func get_all(path_or_api) -> Array:
	if !path_or_api:
		return []
	return _get_store(path_or_api).values()

static func fetch(path):
	if !path:
		return
	return _get_store(path).get(path)

static func update(path, data: Dictionary) -> Dictionary:
	var value = fetch(path)
	if !value || !data:
		return value
	for key in data:
		value[key] = data[key]
	_write_store(path)
	return value

static func delete(path) -> void:
	if !path:
		return
	_get_store(path).erase(path)
	_write_store(path)

static func create(data: Dictionary) -> Dictionary:
	_get_store(data.path)[data.path] = data
	_write_store(data.path)
	return data


static func _get_store(path_or_api):
	if !path_or_api:
		return
	var api = path_or_api.split("/")[0]
	var existing = _global.get(api)
	if existing is Dictionary:
		return existing

	
	var content = _GotmUtility.read_file(_Gotm.get_local_path(api + ".json"))
	if content:
		_global[api] = parse_json(content)
		if !_global[api]:
			_global[api] = {}
	else:
		_global[api] = {}
	return _global[api]
	
static func _write_store(path_or_api) -> void:
	var api = path_or_api.split("/")[0]
	_GotmUtility.write_file(_Gotm.get_local_path(api + ".json"), to_json(_get_store(api)))
