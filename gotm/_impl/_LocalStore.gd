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

class_name _LocalStore
#warnings-disable


const _global = {}

static func get_all(path_or_api: String) -> Array:
	if !path_or_api:
		return []
	return _get_store(path_or_api).values()

static func fetch(path: String):
	if !path:
		return
	return _get_store(path)[path]

static func update(path: String, data: Dictionary) -> Dictionary:
	var value = fetch(path)
	if !value || !data:
		return value
	for key in data:
		value[key] = data[key]
	_write_store(path)
	return value

static func delete(path: String) -> void:
	if !path:
		return
	_get_store(path).erase(path)
	_write_store(path)

static func create(data: Dictionary) -> Dictionary:
	_get_store(data.path)[data.path] = data
	_write_store(data.path)
	return data


static func _get_store(path_or_api: String):
	if !path_or_api:
		return
	var api = path_or_api.split("/")[0]
	var existing = _global.get(api)
	if existing is Dictionary:
		return existing

	var file = File.new()
	file.open(_Gotm.get_local_path(api + ".json"), File.READ)
	var content = file.get_as_text() if file.is_open() else ""
	file.close()
	if content:
		_global[api] = parse_json(content)
		if !_global[api]:
			_global[api] = {}
	else:
		_global[api] = {}
	return _global[api]
	
static func _write_store(path_or_api: String) -> void:
	var api = path_or_api.split("/")[0]
	var file = File.new()
	file.open(_Gotm.get_local_path(api + ".json"), File.WRITE)
	file.store_string(to_json(_get_store(api)))
	file.close()
