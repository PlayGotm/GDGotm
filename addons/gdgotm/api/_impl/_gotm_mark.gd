class_name _GotmMark

enum AuthImplementation { GOTM_AUTH, GOTM_AUTH_LOCAL }
enum Implementation { GOTM_STORE, GOTM_MARK_LOCAL }

const ALLOWED_TYPES = {
	GotmMark.Types.UPVOTE: "upvote",
	GotmMark.Types.DOWNVOTE: "downvote"
	}
const ALLOWED_TARGET_APIS = {"contents": "GotmContent"}


static func _clear_cache() -> void:
	if get_implementation() == Implementation.GOTM_MARK_LOCAL:
		_GotmMarkLocal.clear_cache("marks")
		_GotmMarkLocal.clear_cache("stats")
	else:
		_GotmStore.clear_cache("marks")
		_GotmStore.clear_cache("stats")


static func _coerce_id(resource_or_id) -> String:
	var id = _GotmUtility.coerce_resource_id(resource_or_id, "marks")
	if !(id is String):
		return ""
	return id


static func create(target_or_id, type: GotmMark.Types, is_local: bool = false) -> GotmMark:
	if !(target_or_id is String || ALLOWED_TARGET_APIS.values().has(target_or_id.get("_CLASS_NAME"))):
		push_error("Expected a GotmContent or GotmContent.id string.")
		return null

	var target_id: String = _GotmUtility.coerce_resource_id(target_or_id)
	if !_is_mark_allowed(target_id, type):
		return null

	var data: Dictionary
	if is_local || get_implementation(target_id) == Implementation.GOTM_MARK_LOCAL || !((await _GotmAuth.fetch()).is_registered):
		data = await _GotmMarkLocal.create("marks", {"target": target_id, "name": ALLOWED_TYPES[type]})
	else:
		data = await _GotmStore.create("marks", {"target": target_id, "name": ALLOWED_TYPES[type]})
	if data:
		_clear_cache()
	return _format(data, GotmMark.new())


static func delete(mark_or_id) -> bool:
	if !(mark_or_id is GotmMark || mark_or_id is String):
		push_error("Expected a GotmMark or GotmMark.id string.")
		return false

	var result := false
	var id := _coerce_id(mark_or_id)
	if get_implementation(id) == Implementation.GOTM_MARK_LOCAL:
		result = await _GotmMarkLocal.delete(id)
	else:
		result = await _GotmStore.delete(id)
	_clear_cache()
	return result


static func fetch(mark_or_id) -> GotmMark:
	if !(mark_or_id is GotmMark || mark_or_id is String):
		push_error("Expected a GotmMark or GotmMark.id string.")
		return null

	var id = _coerce_id(mark_or_id)
	var data: Dictionary
	if get_implementation(id) == Implementation.GOTM_MARK_LOCAL:
		data = await _GotmMarkLocal.fetch(id)
	else:
		data = await _GotmStore.fetch(id)
	return _format(data, GotmMark.new())


static func _format(data: Dictionary, mark: GotmMark) -> GotmMark:
	if data.is_empty() || !mark:
		return
	mark.id = data.path
	mark.user_id = data.owner
	mark.target_id = data.target
	mark.type = data.name
	mark.created = data.created
	mark.is_local = !_LocalStore.fetch(data.path).is_empty()
	return mark


static func get_auth_implementation() -> AuthImplementation:
	if get_implementation() == Implementation.GOTM_MARK_LOCAL:
		return AuthImplementation.GOTM_AUTH_LOCAL
	return AuthImplementation.GOTM_AUTH


static func get_count(target_or_id, type: String = "") -> int:
	if !(target_or_id is String || ALLOWED_TARGET_APIS.values().has(target_or_id.get("_CLASS_NAME"))):
		push_error("Expected a GotmContent or GotmContent.id string.")
		return 0

	var target_id: String = _GotmUtility.coerce_resource_id(target_or_id)
	var is_allowed: bool
	if type.is_empty():
		is_allowed = _is_mark_allowed(target_id, GotmMark.Types.values()[0])
	else:
		is_allowed = _is_mark_allowed(target_id, ALLOWED_TYPES.find_key(type))
	if !is_allowed:
		return 0

	var params = {
		"target": target_id,
		"name": "marks/" + type,
	}
	var stat: Dictionary
	var implementation: Implementation = get_implementation(target_id)
	if implementation == Implementation.GOTM_MARK_LOCAL:
		stat = await _GotmMarkLocal.fetch("stats/sum", "received", params)
	else:
		stat = await _GotmStore.fetch("stats/sum", "received", params)
	var local_stat := await _GotmMarkLocal.fetch("stats/sum", "received", params) if implementation != Implementation.GOTM_MARK_LOCAL else {}
	var value: int = 0
	if !stat.is_empty():
		value += stat.value
	if !local_stat.is_empty():
		value += local_stat.value
	return value


static func get_count_with_type(target_or_id, type: GotmMark.Types) -> int:
	return await get_count(target_or_id, ALLOWED_TYPES[type])


static func get_implementation(id: String = "") -> Implementation:
	if !_Gotm.is_global_api("marks") || !_LocalStore.fetch(id).is_empty():
		return Implementation.GOTM_MARK_LOCAL
	return Implementation.GOTM_STORE


static func _is_mark_allowed(target_id: String, type: GotmMark.Types) -> bool:
	var allowed := false
	if ALLOWED_TYPES.has(type) && !target_id.is_empty() && ALLOWED_TARGET_APIS.has(target_id.split("/")[0]):
		allowed = true
	if !allowed:
		push_error("Invalid mark target '" + target_id + "' or mark type.")
	return allowed


static func list_by_target(target_or_id, type: String = "") -> Array:
	if !(target_or_id is String || ALLOWED_TARGET_APIS.values().has(target_or_id.get("_CLASS_NAME"))):
		push_error("Expected a GotmContent or GotmContent.id string.")
		return []

	var auth
	if get_auth_implementation() == AuthImplementation.GOTM_AUTH_LOCAL:
		auth = await _GotmAuthLocal.get_auth_async()
	else:
		auth = await _GotmAuth.get_auth_async()
	var target_id: String = _GotmUtility.coerce_resource_id(target_or_id)
	if !auth || target_id.is_empty():
		return []

	var is_allowed: bool
	if type.is_empty():
		is_allowed = _is_mark_allowed(target_id, GotmMark.Types.values()[0])
	else:
		is_allowed = _is_mark_allowed(target_id, ALLOWED_TYPES.find_key(type))
	if !is_allowed:
		return []

	var params = _GotmUtility.delete_empty({
		"name": type,
		"target": target_id,
		"owner": auth.owner,
	})
	var implementation: Implementation = get_implementation(target_id)
	var query = "byTargetAndOwnerAndName" if !type.is_empty() else "byTargetAndOwner"
	var data_list: Array
	if implementation == Implementation.GOTM_MARK_LOCAL:
		data_list = await _GotmMarkLocal.list("marks", query, params)
	else:
		data_list = await _GotmStore.list("marks", query, params)
	var local_params = params.duplicate()
	local_params.owner = _GotmAuthLocal.get_user()
	var local_data_list = await _GotmMarkLocal.list("marks", query, local_params) if implementation != Implementation.GOTM_MARK_LOCAL else []
	var marks = []
	if !data_list.is_empty():
		for data in data_list:
			marks.append(_format(data, GotmMark.new()))
	if !local_data_list.is_empty():
		for data in local_data_list:
			marks.append(_format(data, GotmMark.new()))
	return marks


static func list_by_target_with_type(target_or_id, type: GotmMark.Types) -> Array:
	return await list_by_target(target_or_id, ALLOWED_TYPES[type])
