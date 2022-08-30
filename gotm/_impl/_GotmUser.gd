class_name _GotmUser
#warnings-disable

static func get_implementation():
	if !_Gotm.has_global_api():
		return _GotmUserLocal
	return _GotmStore

static func fetch(id: String):
	var data = yield(get_implementation().fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmUser"))

static func _format(data, user):
	if !data || !user:
		return
	user.id = data.path
	user.display_name = data.name
	return user
