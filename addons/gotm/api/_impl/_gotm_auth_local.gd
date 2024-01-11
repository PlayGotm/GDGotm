class_name _GotmAuthLocal


static func get_auth() -> _GotmAuthLocalCache:
	return _get_cache()


static func get_auth_async() -> _GotmAuthLocalCache:
	return get_auth()


static func _get_cache() -> _GotmAuthLocalCache:
	if _cache.token:
		return _cache

	var file_path := _Gotm.get_local_path("auth.json")
	var content = _GotmUtility.read_file(file_path)
	if content:
		_GotmUtility.copy(JSON.parse_string(content), _cache)
	else:
		_cache.token = _GotmUtility.create_id()
		_cache.project = _GotmUtility.create_resource_path("games")
		_cache.owner = _GotmUtility.create_resource_path("users")
		_cache.instance = _GotmUtility.create_resource_path("instances")
		_GotmUtility.write_file(file_path, JSON.stringify(_cache.to_dict()))
	_cache.is_guest = true
	return _cache


static func get_user() -> String:
	return _get_cache().owner


class _GotmAuthLocalCache:
	var token: String
	var project: String
	var owner: String
	var is_guest: bool
	var instance: String

	func to_dict() -> Dictionary:
		return {"token": token, "project": project, "owner": owner, "is_guest": is_guest, "instance": instance}


static var _cache := _GotmAuthLocalCache.new()
