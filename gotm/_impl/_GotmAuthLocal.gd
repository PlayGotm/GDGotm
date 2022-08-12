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

class_name _GotmAuthLocal
#warnings-disable

const _cache := {"token": "", "project": "", "owner": ""}

static func _get_cache():
	if _cache.token:
		return _cache
	
	var file_path := _Gotm.get_local_path("auth.json")
	var content = _GotmUtility.read_file(file_path)
	if content:
		_GotmUtility.copy(parse_json(content), _cache)
		if !_cache.get("owner") && _cache.get("user"):
			_cache.owner = _cache.user
			_cache.erase("user")
			_GotmUtility.write_file(file_path, to_json(_cache))
	else:
		_cache.token = _GotmUtility.create_id()
		_cache.project = _GotmUtility.create_resource_path("games")
		_cache.owner = _GotmUtility.create_resource_path("users")
		_GotmUtility.write_file(file_path, to_json(_cache))
	_cache.is_guest = true
	return _cache

static func get_user() -> String:
	return _get_cache().owner

static func get_auth():
	return _get_cache()

static func get_auth_async():
	yield(_GotmUtility.get_tree(), "idle_frame")
	return get_auth()
