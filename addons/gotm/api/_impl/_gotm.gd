class_name _Gotm

static var api_origin: String = "https://api.gotm.io"
static var api_worker_origin: String = "https://worker.gotm.io"
static var storage_api_endpoint: String = "https://storage.gotm.io"

static func get_local_path(path: String = "") -> String:
	return get_user_path("local/" + path)


static func get_user_path(path: String = "") -> String:
	return "user://gotm/" + path


static func get_singleton():
	if !Engine.has_singleton("Gotm"):
		return
	return Engine.get_singleton("Gotm")


static func has_global_api() -> bool:
	return is_global_api("scores") || is_global_api("contents") || is_global_api("marks")


static func is_global_api(api: String) -> bool:
	match api:
		"scores":
			return is_global_feature(Gotm.force_local_scores)
		"contents":
			return is_global_feature(Gotm.force_local_contents)
		"marks":
			return is_global_feature(Gotm.force_local_marks)
		_:
			return false


static func is_global_feature(forceLocal: bool = false) -> bool:
	return !forceLocal && !Gotm.project_key.is_empty()