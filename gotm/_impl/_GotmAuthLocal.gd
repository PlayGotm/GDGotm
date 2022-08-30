class_name _GotmAuthLocal
#warnings-disable

const _cache := {"token": "", "project": "", "owner": ""}

static func _get_cache():
	if _cache.token:
		return _cache
	
	var file_path := _Gotm.get_local_path("auth.json")
	var content = _GotmUtility.read_file(file_path)
	if content:
		_GotmUtility.copy(parse_json(content), _cache)
		if !_cache.get("owner") && _cache.get("user"):
			_cache.owner = _cache.user
			_cache.erase("user")
			_GotmUtility.write_file(file_path, to_json(_cache))
	else:
		_cache.token = _GotmUtility.create_id()
		_cache.project = _GotmUtility.create_resource_path("games")
		_cache.owner = _GotmUtility.create_resource_path("users")
		_GotmUtility.write_file(file_path, to_json(_cache))
	_cache.is_guest = true
	return _cache

static func get_user() -> String:
	return _get_cache().owner

static func get_auth():
	return _get_cache()

static func get_auth_async():
	yield(_GotmUtility.get_tree(), "idle_frame")
	return get_auth()
