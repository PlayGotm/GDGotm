# MIT License
#
# Copyright (c) 2020-2022 Macaroni Studios AB
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name _GotmBlobLocal
#warnings-disable


static func create(api: String, body: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	api = api.split("/")[0]
	var data = body.data
	if !(data is PoolByteArray):
		data = var2bytes(data)
		
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

static func _format(data: Dictionary):
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