class_name _Gotm


static func get_config() -> GotmConfig:
	var config := get_global().config
	if !config:
		push_error("Gotm Error: Could not get config. Make sure to initialize first, Gotm.initialize(...).") # TODO: Make sure Gotm.initialize doesnt get moved around during WIP or rename this.
	return get_global().config


static func get_global() -> _GotmGlobalData:
	var _global = _GotmUtility.get_static_variable(_Gotm, "_global", null)
	if !_global:
		_global = _GotmGlobalData.new()
		_GotmUtility.set_static_variable(_Gotm, "_global", _global)
	return _global


static func get_local_path(path: String = "") -> String:
	return get_user_path("local/" + path)


static func get_user_path(path: String = "") -> String:
	return "user://gotm/" + path


static func get_project_key() -> String:
	return get_global().config.project_key


static func get_singleton():
	if !Engine.has_singleton("Gotm"):
		return
	return Engine.get_singleton("Gotm")


static func has_global_api() -> bool:
	return is_global_api("scores") || is_global_api("contents") || is_global_api("marks")


static func initialize(config: GotmConfig) -> void:
	var global := get_global()
	global.config = _GotmUtility.copy(config, GotmConfig.new())
	var err := DirAccess.make_dir_recursive_absolute(get_local_path())
	if err != OK:
		push_error("Could not initialize Gotm. DirAccess Error: ", err)


static func is_global_api(api: String) -> bool:
	var config := get_config()
	match api:
		"scores":
			return is_global_feature(config.force_local_scores)
		"contents":
			return is_global_feature(config.force_local_contents)
		"marks":
			return is_global_feature(config.force_local_marks)
		_:
			return false


static func is_global_feature(forceLocal: bool = false) -> bool:
	return !forceLocal && !get_project_key().is_empty()


class _GotmGlobalData:
	var config: GotmConfig
	var version: String = "2.0.0"
	var apiOrigin: String = "https://api.gotm.io"
	var apiWorkerOrigin: String = "https://gotm-api-worker-eubrk3zsia-uk.a.run.app"
	var storageApiEndpoint: String = "https://storage.googleapis.com/gotm-api-production-d13f0.appspot.com"
