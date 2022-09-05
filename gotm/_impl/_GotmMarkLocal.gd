class_name _GotmMarkLocal
#warnings-disable


static func delete_by_target_sync(target):
	var to_delete = []
	for mark in _LocalStore.get_all("marks"):
		if mark.target == target:
			to_delete.append(mark)
	for mark in to_delete:
		_LocalStore.delete(mark.path)

static func create(api: String, data: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	var score = {
		"path": _GotmUtility.create_resource_path(api),
		"target": data.target,
		"owner": _GotmAuthLocal.get_user(),
		"name": data.name,
		"created": _GotmUtility.get_iso_from_unix_time()
	}
	return _format(_LocalStore.create(score))


static func delete(id: String) -> void:
	yield(_GotmUtility.get_tree(), "idle_frame")
	_LocalStore.delete(id)

static func fetch(path: String, query: String = "", params: Dictionary = {}, authenticate: bool = false) -> Dictionary:
	yield(_GotmUtility.get_tree(), "idle_frame")
	var path_parts = path.split("/")
	var api = path_parts[0]
	var id = path_parts[1]
	if api == "stats" && id == "sum" && query == "received":
		return {"path": _GotmStore.create_request_path(path, query, params), "value": _fetch_count(params)}
	return _format(_LocalStore.fetch(path))


static func _fetch_count(params: Dictionary) -> int:
	var count := 0
	var name_parts = params.name.split("/")
	if name_parts.size() != 2 || name_parts[0] != "marks":
		return count
	var mark_name = name_parts[1]
	for mark in _LocalStore.get_all("marks"):
		if mark.target == params.target && mark.name == mark_name:
			count += 1
	return count

static func list(api: String, query: String, params: Dictionary = {}, authenticate: bool = false) -> Array:
	yield(_GotmUtility.get_tree(), "idle_frame")
	var marks := []
	if query == "byTargetAndOwner":
		for mark in _LocalStore.get_all("marks"):
			if mark.target == params.target && mark.owner == params.owner:
				marks.append(_format(mark))
	elif query == "byTargetAndOwnerAndName":
		for mark in _LocalStore.get_all("marks"):
			if mark.target == params.target && mark.owner == params.owner && mark.name == params.name:
				marks.append(_format(mark))
	return marks

static func clear_cache(path: String) -> void:
	pass

static func _format(data):
	if !data:
		return
	data = _GotmUtility.copy(data, {})
	data.created = _GotmUtility.get_unix_time_from_iso(data.created)
	return data
