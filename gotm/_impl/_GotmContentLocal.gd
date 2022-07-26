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

class_name _GotmContentLocal
#warnings-disable


static func create(api: String, data: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	var created =  _GotmUtility.get_iso_from_unix_time()
	var score = {
		"path": _GotmUtility.create_resource_path(api),
		"author": _GotmAuthLocal.get_user(),
		"name": data.name,
		"key": data.key,
		"private": data.private,
		"props": data.props,
		"updated": created,
		"created": created
	}
	return _format(_LocalStore.create(score))

static func update(id: String, data: Dictionary):
	yield(_GotmUtility.get_tree(), "idle_frame")
	return _format(_LocalStore.update(id, data))

static func delete(id: String) -> void:
	yield(_GotmUtility.get_tree(), "idle_frame")
	_LocalStore.delete(id)

static func fetch(path: String, query: String = "", params: Dictionary = {}, authenticate: bool = false) -> Dictionary:
	yield(_GotmUtility.get_tree(), "idle_frame")
	return _format(_LocalStore.fetch(path))

static func list(api: String, query: String, params: Dictionary = {}, authenticate: bool = false) -> Array:
	yield(_GotmUtility.get_tree(), "idle_frame")
	if query == "byKey":
		return _get_by_key(params.project, params.key)
	return []

static func clear_cache(path: String) -> void:
	pass


static func _get_by_key(project: String, key: String):
	for content in _LocalStore.get_all("contents"):
		if !content.private && content.project == project && content.key == key:
			return [_format(content)]
	return []

static func _format(data: Dictionary):
	if !data:
		return
	data = _GotmUtility.copy(data, {})
	data.updated = _GotmUtility.get_unix_time_from_iso(data.updated)
	data.created = _GotmUtility.get_unix_time_from_iso(data.created)
	return data
