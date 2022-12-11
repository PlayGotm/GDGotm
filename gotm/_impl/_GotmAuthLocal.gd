class_name _GotmAuthLocal
#warnings-disable

const CACHE:Dictionary = {
					"token": "", 
					"project": "", 
					"owner": ""
				}

static func _get_cache()->Dictionary:
	if CACHE.get('token'):
		return CACHE
	
	var file_path:String = _Gotm.get_local_path("auth.json")
	var content = _GotmUtility.read_file(file_path)
	if content:
		_GotmUtility.copy(parse_json(content), CACHE)
		if !CACHE.get('owner') && CACHE.get('user'):
			CACHE['owner'] = CACHE.user
			CACHE.erase("user")
			_GotmUtility.write_file(file_path, to_json(CACHE))
	else:
		CACHE['token'] = _GotmUtility.create_id()
		CACHE['project'] = _GotmUtility.create_resource_path("games")
		CACHE['owner'] = _GotmUtility.create_resource_path("users")
		_GotmUtility.write_file(file_path, to_json(CACHE))
	CACHE["is_guest"] = true
	return CACHE

static func get_user()->String:
	return _get_cache().owner

static func get_auth()->Dictionary:
	return _get_cache()

static func get_auth_async()->Dictionary:
	yield(_GotmUtility.get_tree(), "idle_frame")
	return get_auth()
