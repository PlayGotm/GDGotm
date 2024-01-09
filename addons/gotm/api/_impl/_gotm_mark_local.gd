class_name _GotmMarkLocal


static func clear_cache(_path: String) -> void:
	pass


static func create(api: String, data: Dictionary) -> Dictionary:
	var score := {
		"path": _GotmUtility.create_resource_path(api),
		"target": data.target,
		"owner": _GotmAuthLocal.get_user(),
		"name": data.name,
		"created": _GotmUtility.get_iso_from_unix_time()
	}
	return _format(_LocalStore.create(score))


static func delete(id: String) -> bool:
	return _LocalStore.delete(id)


static func delete_by_target_sync(target: String) -> bool:
	var result := false
	var to_delete := []
	for mark in _LocalStore.get_all("marks"):
		if mark.target == target:
			to_delete.append(mark)
	if !to_delete.is_empty():
		result = true
	for mark in to_delete:
		if _LocalStore.delete(mark.path) == false:
			result = false
	return result


static func fetch(path: String, query: String = "", params: Dictionary = {}, _authenticate: bool = false) -> Dictionary:
	var path_parts := path.split("/")
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


static func _format(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	data = _GotmUtility.copy(data, {})
	data.created = _GotmUtility.get_unix_time_from_iso(data.created)
	return data


static func list(_api: String, query: String, params: Dictionary = {}, _authenticate: bool = false) -> Array:
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
