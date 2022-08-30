class_name _Gotm
#warnings-disable

class __GotmGlobalData:
	var config: GotmConfig
	var version: String = "0.0.1"
	var apiOrigin: String = "https://api.gotm.io"
	var apiWorkerOrigin: String = "https://gotm-api-worker-eubrk3zsia-uk.a.run.app"
	var storageApiEndpoint: String = "https://storage.googleapis.com/gotm-api-production-d13f0.appspot.com"
	var classes: Dictionary = {}

const _version = "0.0.1"
const _global = {"value": null}
static func get_global() -> __GotmGlobalData:
	return _global.value

static func create_instance(name: String):
	return get_global().classes[name].new()

static func initialize(config: GotmConfig, classes: Dictionary) -> void:
	_global.value = __GotmGlobalData.new()
	var global := get_global()
	global.config = _GotmUtility.copy(config, GotmConfig.new())
	global.classes = classes
	var directory = Directory.new()
	directory.make_dir_recursive(get_local_path(""))

static func is_live() -> bool:
	return !!get_singleton()

static func is_global_feature(forceLocal: bool = false, forceGlobal: bool = false) -> bool:
	return !forceLocal && (is_live() || forceGlobal) && get_project_key()

static func get_project_key() -> String:
	return get_global().config.project_key

static func get_local_path(path: String = "") -> String:
	return get_path("local/" + path)

static func get_path(path: String = "") -> String:
	return "user://gotm/" + path

static func get_config() -> GotmConfig:
	return get_global().config
	
static func get_singleton():
	if !Engine.has_singleton("Gotm"):
		return
	return Engine.get_singleton("Gotm")

static func is_global_api(api: String) -> bool:
	var config := get_config()
	match api:
		"scores":
			return is_global_feature(config.force_local_scores, config.beta_unsafe_force_global_scores)
		"contents":
			return is_global_feature(config.force_local_contents, config.beta_unsafe_force_global_contents)
		"marks":
			return is_global_feature(config.force_local_marks, config.beta_unsafe_force_global_marks)
		_:
			return false


static func has_global_api() -> bool:
	return is_global_api("scores") || is_global_api("contents") || is_global_api("marks")
