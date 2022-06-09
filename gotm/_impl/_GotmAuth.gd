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

const _cache := {"auth": null, "queue": null}

class _GotmAuthData:
	var refresh_token: String
	var token: String
	# Expiration date in UNIX epoch time seconds
	var expired: int
	
	

static func get_token() -> String:
	var auth = _cache.auth
	if auth and auth.token and auth.expired < OS.get_unix_time() - 60:
		return auth.token
	return ""

static func get_project_from_token(token: String) -> String:
	if not token:
		return ""
	var parts = token.split(".")
	if parts.size() != 3:
		return ""
	

	var data = parse_json(Marshalls.base64_to_utf8(parts[1] + "=="))
	if not data or not data.project:
		return ""
		
	return data.project

static func get_token_async():
	var token = get_token()
	if token:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return token
	
	if _cache.queue:
		yield(_cache.queue.add(), "completed")
		return get_token()
	
	var queue := _GotmUtility.QueueSignal.new()
	_cache.queue = queue
	var sig = _get_refreshed_auth(_cache.auth)
	var auth = yield(sig, "completed")
	_cache.auth = auth
	_cache.queue = null
	queue.trigger()
	return get_token()

static func _get_refreshed_auth(auth: _GotmAuthData) -> _GotmAuthData:
	var projectKey = Gotm.get_config().projectKey
	if auth and auth.refresh_token:
		var data = yield(_create_authentication({"refreshToken": auth.refresh_token}), "completed")
		if data:
			return _format_auth_data(data)
	
	if not projectKey:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	
	var gotm = _Gotm.get_singleton()
	if gotm:
		var data = yield(gotm.create_project_authentication(projectKey), "completed")
		return _format_auth_data(data)
	
	var user_auth = yield(_get_user_auth(), "completed")
	if not user_auth:
		return
	
	var data = yield(_create_authentication({"project": projectKey}, ["authorization: Bearer " + user_auth.token]), "completed")
	return _format_auth_data(data)

static func _format_auth_data(data) -> _GotmAuthData:
	if not data:
		return null
	var auth: _GotmAuthData = _GotmUtility.copy(data, _GotmAuthData.new())
	auth.expired = _GotmUtility.get_unix_time_from_iso(data.expired)
	return auth

static func _get_user_auth() -> _GotmAuthData:
	var file_path := "user://gotm/user_auth.json"
	var file = File.new()
	file.open(file_path, File.READ_WRITE)
	var content = file.get_as_text()
	file.close()
	if content:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return _format_auth_data(parse_json(content))
	
	var data = yield(_create_authentication(), "completed")
	if not data:
		return
	
	file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(to_json(data))
	file.close()
	
	return _format_auth_data(data)


static func _create_authentication(body: Dictionary = {}, headers: PoolStringArray = []) -> Dictionary:
	return yield(_GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications", HTTPClient.METHOD_POST, body, headers), "completed")
