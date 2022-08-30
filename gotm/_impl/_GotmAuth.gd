class_name _GotmAuth
#warnings-disable

const _global := {"auth": null, "queue": null, "has_read_from_file": false, "gotm_auth": null}

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

static func fetch():
	var auth = yield(get_auth_async(), "completed")
	if !auth:
		auth = _global.gotm_auth
	if !auth:
		auth = _GotmAuthLocal.get_auth()
	if !auth:
		return
	var instance = _Gotm.create_instance("GotmAuth")
	instance.user_id = auth.owner
	instance.is_registered = !auth.is_guest
	return instance

static func get_auth():
	var auth = _global.auth
	if !auth && !_global.has_read_from_file:
		_global.has_read_from_file = true
		auth = _read_auth(PROJECT_AUTH_NAME)
		if auth:
			_global.auth = auth
	# Only return valid project auths
	if !_is_auth_valid(auth) || !auth.project || !auth.project_key:
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
	if gotm && !_global.gotm_auth:
		_global.gotm_auth = _format_auth_data(yield(gotm.get_auth(), "completed"))
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
	var refreshed: _GotmAuthData = yield(_create_authentication({"refreshToken": auth.refresh_token}), "completed")
	if !refreshed:
		return
	refreshed.project_key = auth.project_key
	return refreshed

static func _get_refreshed_project_auth(auth: _GotmAuthData):
	var project_key = _Gotm.get_project_key()
	if !project_key:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	if auth && auth.refresh_token && auth.project && auth.project_key && auth.project_key == project_key:
		var data = yield(_refresh_auth(auth), "completed")
		if data:
			return data

	# Gotm manages user auths for us.
	var gotm = _Gotm.get_singleton()
	if gotm:
		var data = yield(gotm.create_project_authentication(project_key), "completed")
		var formatted = _format_auth_data(data)
		formatted.project_key = project_key
		return formatted

	# We manage user auths ourselves.
	var user_auth
#	if _Gotm.get_global().apiOrigin.begins_with("http://localhost"):
#		user_auth = yield(_create_development_user_authentication(), "completed")
	if !user_auth:
		user_auth = _read_auth(GUEST_AUTH_NAME)
	if !user_auth || user_auth.project_key != project_key:
		user_auth = yield(_create_authentication(), "completed")
	if !_is_auth_valid(user_auth) && user_auth && user_auth.refresh_token:
		user_auth = yield(_refresh_auth(user_auth), "completed")
	_write_auth(user_auth)

	if !user_auth:
		return
	var project_auth: _GotmAuthData = yield(_create_authentication({"project": project_key}, ["authorization: Bearer " + user_auth.token]), "completed")
	project_auth.project_key = project_key
	return project_auth

static func _is_auth_valid(auth: _GotmAuthData) -> bool:
	if !auth || !auth.token || !(auth.expired / 1000 > OS.get_unix_time() + 60):
		return false
	if auth.project && auth.project_key != _Gotm.get_project_key():
		return false
	
	if _Gotm.get_singleton():
		if !auth.owner || !_global.gotm_auth || auth.owner != _global.gotm_auth.owner:
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
	auth.expired = _GotmUtility.get_unix_time_from_iso(data.expired)
	return auth

const PROJECT_AUTH_NAME := "project_auth.json"
const GUEST_AUTH_NAME := "guest_auth.json"


static func _read_auth(name: String):
	var content = _GotmUtility.read_file(_Gotm.get_path(name))
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
	elif auth.is_guest:
		name = GUEST_AUTH_NAME
	else:
		return
	_GotmUtility.write_file(_Gotm.get_path(name), to_json({"data": auth.data, "project_key": auth.project_key}))

static func _create_authentication(body: Dictionary = {}, headers: PoolStringArray = []) -> Dictionary:
	var result = yield(_GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications", HTTPClient.METHOD_POST, body, headers), "completed")
	if !result.ok:
		return
	return _format_auth_data(result.data)

static func _create_development_user_authentication() -> Dictionary:
	var email = "gdgotm@mail.com"
	var result = yield(_GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications/email?query=withCallbackUrl&callbackUrl=https://website.com&email=" + email), "completed")
	if !result.ok || !(result.data.token is String):
		return
	var sign_in_url = result.data.token
	sign_in_url += "&email=" + email
	
	return yield(_create_authentication({"signInUrl": sign_in_url}), "completed")
