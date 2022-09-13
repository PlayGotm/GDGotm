class_name _GotmBlobLocal
#warnings-disable


static func create(api: String, body: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	api = api.split("/")[0]
	var data = body.data
	if !(data is PoolByteArray):
		return
		
	var blob = {
		"path": _GotmUtility.create_resource_path(api),
		"author": _GotmAuthLocal.get_user(),
		"target": body.target,
		"size": data.size()
	}
	_GotmUtility.write_file(_Gotm.get_local_path(blob.path), data)
	return _format(_LocalStore.create(blob))
#

static func fetch(path: String, query: String = "", params: Dictionary = {}, authenticate: bool = false) -> Dictionary:
	yield(_GotmUtility.get_tree(), "idle_frame")
	var is_data = path.begins_with(_Gotm.get_global().storageApiEndpoint)
	if is_data:
		path = path.replace(_Gotm.get_global().storageApiEndpoint + "/", "")
	
	var blob = _LocalStore.fetch(path)
	if !blob:
		return
	
	if is_data:
		return _GotmUtility.read_file(_Gotm.get_local_path(blob.path), true)
	
	return _format(blob)

static func _format(data):
	if !data:
		return
	data = _GotmUtility.copy(data, {})
	return data

static func delete_sync(path):
	var blob = _LocalStore.fetch(path)
	if !blob:
		return
	_LocalStore.delete(path)
	_GotmUtility.write_file(_Gotm.get_local_path(blob.path), null)