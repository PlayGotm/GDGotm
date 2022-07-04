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

class_name _GotmAuth
#warnings-disable

const _global := {"auth": null, "queue": null, "has_read_from_file": false, "user_id": null}

class _GotmAuthData:
	var data: Dictionary
	var refresh_token: String
	var token: String
	# Expiration date in UNIX epoch time milliseconds
	var expired: int
	var is_guest: bool
	var owner: String
	var project: String
	var project_key: String

static func get_auth():
	var auth = _global.auth
	if !auth && ! _global.has_read_from_file:
		_global.has_read_from_file = true
		auth = _read_auth(PROJECT_AUTH_NAME)
		if auth:
			_global.auth = auth
	# Only return valid project auths
	if !_is_auth_valid(auth) || !auth.project_key:
		return
	return auth

static func get_auth_async():
	var auth = get_auth()
	if auth:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return auth
	
	if _global.queue:
		yield(_global.queue.add(), "completed")
		return get_auth()
	
	var queue := _GotmUtility.QueueSignal.new()
	_global.queue = queue
	
	var gotm = _Gotm.get_singleton()
	if gotm && !_global.user_id:
		_global.user_id = yield(gotm.get_user_id(), "completed")
		auth = get_auth()
		_global.auth = auth
	if !auth:
		auth = yield(_get_refreshed_project_auth(_global.auth), "completed")
		_write_auth(auth)
	_global.auth = auth
	_global.queue = null
	queue.trigger()
	return get_auth()


static func _get_project_from_token(token: String) -> String:
	if !token:
		return ""
	var parts = token.split(".")
	if parts.size() != 3:
		return ""
	
	var data = parse_json(Marshalls.base64_to_utf8(parts[1] + "=="))
	if !data || !data.get("project"):
		return ""
		
	return data.project

static func _refresh_auth(auth: _GotmAuthData) -> _GotmAuthData:
	return yield(_create_authentication({"refreshToken": auth.refresh_token}), "completed")

static func _get_refreshed_project_auth(auth: _GotmAuthData):
	var project_key = _Gotm.get_project_key()
	if !project_key:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	if auth && auth.refresh_token && auth.project_key && auth.project_key == project_key:
		var data = yield(_refresh_auth(auth), "completed")
		if data:
			return data

	# Gotm manages user auths for us.
	var gotm = _Gotm.get_singleton()
	if gotm:
		var data = yield(gotm.create_project_authentication(project_key), "completed")
		return _format_auth_data(data)

	# We manage user auths ourselves.
	var user_auth = _read_auth(GUEST_AUTH_NAME)
	if !user_auth:
		user_auth = yield(_create_authentication(), "completed")
	if user_auth && user_auth.project != project_key:
		user_auth = yield(_create_authentication(), "completed")
	if !_is_auth_valid(user_auth) && user_auth && user_auth.refresh_token:
		user_auth = yield(_refresh_auth(user_auth), "completed")
	_write_auth(user_auth)

	if !user_auth:
		return
	return yield(_create_authentication({"project": project_key}, ["authorization: Bearer " + user_auth.token]), "completed")

static func _is_auth_valid(auth: _GotmAuthData) -> bool:
	if !auth || !auth.token || !(auth.expired / 1000 > OS.get_unix_time() + 60):
		return false
	if auth.project_key && auth.project_key != _Gotm.get_project_key():
		return false
	var gotm = _Gotm.get_singleton()
	if gotm:
		if !auth.owner || auth.owner != _global.user_id:
			return false
	return true



static func _format_auth_data(data) -> _GotmAuthData:
	if !data:
		return null
	var auth := _GotmAuthData.new()
	auth.data = data
	auth.token = data.token
	auth.refresh_token = data.refreshToken
	auth.owner = data.owner
	auth.is_guest = data.isAnonymous
	auth.project = _get_project_from_token(data.token)
	auth.project_key = _Gotm.get_project_key()
	auth.expired = _GotmUtility.get_unix_time_from_iso(data.expired)
	return auth

const PROJECT_AUTH_NAME := "project_auth.json"
const GUEST_AUTH_NAME := "guest_auth.json"


static func _read_auth(name: String):
	var file := File.new()
	file.open(_Gotm.get_path(name), File.READ_WRITE)
	var content = file.get_as_text() if file.is_open() else ""
	file.close()
	if !content:
		return
	var parsed = parse_json(content)
	var auth = _format_auth_data(parsed.data)
	auth.project_key = parsed.project_key
	return auth

static func _write_auth(auth: _GotmAuthData):
	if !auth:
		return
	var name := ""
	if auth.project:
		name = PROJECT_AUTH_NAME
	else:
		name = GUEST_AUTH_NAME
	var file := File.new()
	file.open(_Gotm.get_path(name), File.WRITE)
	if file.is_open():
		file.store_string(to_json({"data": auth.data, "project_key": auth.project_key}))
	file.close()

static func _create_authentication(body: Dictionary = {}, headers: PoolStringArray = []) -> Dictionary:
	var result = yield(_GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications", HTTPClient.METHOD_POST, body, headers), "completed")
	if !result.ok:
		return
	return _format_auth_data(result.data)
