class_name _GotmUser

enum Implementation { GOTM_STORE, GOTM_USER_LOCAL }


static func fetch(id: String) -> GotmUser:
	if get_implementation() == Implementation.GOTM_USER_LOCAL:
		return null
	else:
		var data: Dictionary = await _GotmStore.fetch(id)
		return _format(data, GotmUser.new())


static func _format(data: Dictionary, user: GotmUser) -> GotmUser:
	if data.is_empty() || !user:
		return null
	user.id = data.path
	user.display_name = data.name
	return user


static func get_implementation() -> Implementation:
	if !_Gotm.has_global_api():
		return Implementation.GOTM_USER_LOCAL
	return Implementation.GOTM_STORE
