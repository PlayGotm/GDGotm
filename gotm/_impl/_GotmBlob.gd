class_name _GotmBlob
#warnings-disable


static func get_implementation(id = null):
	var config := _Gotm.get_config()
	if _LocalStore.fetch(id) || !_Gotm.has_global_api():
		return _GotmBlobLocal
	return _GotmStore


static func fetch(blob_or_id):
	var id = _coerce_id(blob_or_id)
	var data = yield(get_implementation(id).fetch(id), "completed")
	return _format(data, _Gotm.create_instance("GotmBlob"))

static func get_data(blob_or_id, type = ""):
	var id = _coerce_id(blob_or_id)
	if !id:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	var data = yield(get_implementation(id).fetch(_Gotm.get_global().storageApiEndpoint + "/" + id), "completed")
	if !data || !type:
		return data
		
	match type:
		"node":
			return bytes2var(data, true).instance()			
		"variant":
			return bytes2var(data, true)
		_:
			return data

static func _coerce_id(resource_or_id):
	return _GotmUtility.coerce_resource_id(resource_or_id, "blobs")

static func _format(data, blob):
	if !data || !blob:
		return
	blob.id = data.path
	blob.size = int(data.size)
	blob.is_local = !!_LocalStore.fetch(data.path)
	return blob
