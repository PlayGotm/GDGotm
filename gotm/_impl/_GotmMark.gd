class_name _GotmMark
#warnings-disable




static func get_implementation(id = null):
	var config := _Gotm.get_config()
	if !_Gotm.is_global_api("marks") || _LocalStore.fetch(id):
		return _GotmMarkLocal
	return _GotmStore

static func get_auth_implementation():
	if get_implementation() == _GotmMarkLocal:
		return _GotmAuthLocal
	return _GotmAuth


const ALLOWED_NAMES = ["upvote", "downvote"]
const ALLOWED_TARGET_APIS = ["contents"]

static func _is_mark_allowed(target_id, name) -> bool:
	if !target_id || !name || !ALLOWED_NAMES.has(name):
		return false
	return ALLOWED_TARGET_APIS.has(target_id.split("/")[0])

static func create(target_or_id, name: String, is_local: bool = false):
	var target_id = _GotmUtility.coerce_resource_id(target_or_id)
	if !_is_mark_allowed(target_id, name):
		yield(_GotmUtility.get_tree(), "idle_frame")
		push_error("Invalid mark target '" + _GotmUtility.to_stable_json(target_id) + "' or mark name '" + _GotmUtility.to_stable_json(name) + "'.")
		return
	var implementation = _GotmMarkLocal if is_local else get_implementation(target_id)
	if implementation != _GotmMarkLocal && !(yield(_GotmAuth.fetch(), "completed")).is_registered:
		implementation = _GotmMarkLocal
	var data = yield(implementation.create("marks", {"target": target_id, "name": name}), "completed")
	if data:
		_clear_cache()
	return _format(data, _Gotm.create_instance("GotmMark"))


static func delete(mark_or_id) -> void:
	var id = _coerce_id(mark_or_id)
	yield(get_implementation(id).delete(id), "completed")
	_clear_cache()

static func fetch(mark_or_id):
	var id = _coerce_id(mark_or_id)
	var data = yield(get_implementation(id).fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmMark"))

static func list_by_target(target_or_id, name) -> Array:
	var auth = yield(get_auth_implementation().get_auth_async(), "completed")
	var target_id = _GotmUtility.coerce_resource_id(target_or_id)
	if !auth || !target_id || (name && !_is_mark_allowed(target_id, name)):
		return []
	
	var params = _GotmUtility.delete_empty({
		"name": name,
		"target": target_id,
		"owner": auth.owner,
	})
	var implementation = get_implementation(target_id)
	var query = "byTargetAndOwnerAndName" if name else "byTargetAndOwner"
	var data_list = yield(implementation.list("marks", query, params), "completed")
	var local_params = params.duplicate()
	local_params.owner = _GotmAuthLocal.get_user()
	var local_data_list = yield(_GotmMarkLocal.list("marks", query, local_params), "completed") if implementation != _GotmMarkLocal else []
	var marks = []
	if data_list:
		for data in data_list:
			marks.append(_format(data, _Gotm.create_instance("GotmMark")))
	if local_data_list:
		for data in local_data_list:
			marks.append(_format(data, _Gotm.create_instance("GotmMark")))
	return marks 	

static func get_count(target_or_id, name) -> int:
	var target_id = _GotmUtility.coerce_resource_id(target_or_id)
	if !target_id || !name || !_is_mark_allowed(target_id, name):
		yield(_GotmUtility.get_tree(), "idle_frame")
		return 0
	
	var implementation = get_implementation(target_id)
	var params = {
		"target": target_id,
		"name": "marks/" + name,
	}
	var stat = yield(implementation.fetch("stats/sum", "received", params), "completed")
	var local_stat = yield(_GotmMarkLocal.fetch("stats/sum", "received", params), "completed") if implementation != _GotmMarkLocal else []
	var value: int = 0
	if stat:
		value += stat.value
	if local_stat:
		value += local_stat.value
	return value

static func _clear_cache():
	get_implementation().clear_cache("marks")
	get_implementation().clear_cache("stats")



static func _format(data, mark):
	if !data || !mark:
		return
	mark.id = data.path
	mark.user_id = data.owner
	mark.target_id = data.target
	mark.name = data.name
	mark.created = data.created
	mark.is_local = !!_LocalStore.fetch(data.path)
	return mark


static func _coerce_id(resource_or_id):
	return _GotmUtility.coerce_resource_id(resource_or_id, "marks")