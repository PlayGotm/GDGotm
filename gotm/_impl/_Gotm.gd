class_name _Gotm

class __GotmGlobalData:
	var config: GotmConfig
	var version: String = "0.0.1"
	var apiOrigin: String = "https://api.gotm.io"

const _version = "0.0.1"
const _global = {"value": null}
static func get_global() -> __GotmGlobalData:
	return _global.value

static func initialize(config: GotmConfig) -> void:
	_global.value = __GotmGlobalData.new()
	var global := get_global()
	global.config = _GotmUtility.copy(config, GotmConfig.new())
	var gotm = get_singleton()
	if gotm:
		gotm.initialize(global)

static func is_live() -> bool:
	return get_singleton()

static func get_config() -> GotmConfig:
	return _GotmUtility.copy(get_global().config, GotmConfig.new())
	
static func get_singleton():
	return Engine.get_singleton("Gotm")