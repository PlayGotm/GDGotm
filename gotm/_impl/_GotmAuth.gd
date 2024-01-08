class_name _GotmAuth


const GUEST_AUTH_NAME := "guest_auth.json"
const PROJECT_AUTH_NAME := "project_auth.json"


static func _create_authentication(body: Dictionary = {}, headers: PackedStringArray = []) -> _GotmAuthData:
	var result = await _GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications", HTTPClient.METHOD_POST, body, headers)
	if !result.ok:
		return null
	return _format_auth_data(result.data)


static func fetch() -> GotmAuth:
	var auth = await get_auth_async()
	if !auth:
		var _global: _GotmAuthGlobalData = _GotmUtility.get_static_variable(_GotmAuth, "_global", _GotmAuthGlobalData.new())
		auth = _global.gotm_auth
	if !auth:
		auth = _GotmAuthLocal.get_auth()
	if !auth:
		return null
	var instance := GotmAuth.new()
	instance.user_id = auth.owner
	instance.is_registered = !auth.is_guest
	return instance


static func _format_auth_data(data: Dictionary) -> _GotmAuthData:
	if data.is_empty():
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


static func get_auth() -> _GotmAuthData:
	var _global: _GotmAuthGlobalData = _GotmUtility.get_static_variable(_GotmAuth, "_global", _GotmAuthGlobalData.new())
	var auth = _global.auth
	if !auth && !_global.has_read_from_file:
		_global.has_read_from_file = true
		auth = _read_auth(PROJECT_AUTH_NAME)
		if auth:
			_global.auth = auth
	# Only return valid project auths
	if !_is_auth_valid(auth) || auth.project.is_empty() || auth.project_key.is_empty():
		return null
	return auth


static func get_auth_async() -> _GotmAuthData:
	var auth = get_auth()
	if auth:
		await _GotmUtility.get_tree().process_frame
		return auth

	var _global: _GotmAuthGlobalData = _GotmUtility.get_static_variable(_GotmAuth, "_global", _GotmAuthGlobalData.new())
#	if _global.queue:
#		_global.queue.add()
#		return get_auth()

#	var queue := _GotmUtility.QueueSignal.new()
#	_global.queue = queue

	var gotm = _Gotm.get_singleton()
	if gotm && !_global.gotm_auth:
		_global.gotm_auth = _format_auth_data(await(gotm.get_auth()))
		auth = get_auth()
		_global.auth = auth
	if !auth:
		auth = await _get_refreshed_project_auth(_global.auth)
		_write_auth(auth)
	_global.auth = auth
#	_global.queue = null
#	queue.trigger()
	return get_auth()


static func _get_project_from_token(token: String) -> String:
	if token.is_empty():
		return ""
	var parts = token.split(".")
	if parts.size() != 3:
		return ""
	var data: Dictionary = JSON.parse_string(Marshalls.base64_to_utf8(parts[1] + "=="))
	if data.is_empty() || data.get("project", "").is_empty():
		return ""
	return data.project


static func _get_refreshed_project_auth(auth: _GotmAuthData) -> _GotmAuthData:
	var project_key := _Gotm.get_project_key()
	if project_key.is_empty():
		await _GotmUtility.get_tree().process_frame
		return null
	if auth && !auth.refresh_token.is_empty() && !auth.project.is_empty() && !auth.project_key.is_empty() && auth.project_key == project_key:
		var data = await _refresh_auth(auth)
		if data:
			return data

	# Gotm manages user auths for us.
	var gotm = _Gotm.get_singleton()
	if gotm:
		var data = await gotm.create_project_authentication(project_key)
		var formatted = _format_auth_data(data)
		formatted.project_key = project_key
		return formatted

	# We manage user auths ourselves.
	var user_auth: _GotmAuthData
#	if _Gotm.get_global().apiOrigin.begins_with("http://localhost"):
#		user_auth = await _create_development_user_authentication()
	if !user_auth:
		user_auth = _read_auth(GUEST_AUTH_NAME)
	if !user_auth || user_auth.project_key != project_key:
		user_auth = await _create_authentication()
	if !_is_auth_valid(user_auth) && user_auth && !user_auth.refresh_token.is_empty():
		user_auth = await _refresh_auth(user_auth)
	_write_auth(user_auth)

	if !user_auth:
		return
	var project_auth: _GotmAuthData = await _create_authentication({"project": project_key}, ["authorization: Bearer " + user_auth.token])
	if !project_auth:
		push_error("[GotmAuth] Could not get project authentication. Is project key valid?")
		return
	project_auth.project_key = project_key
	return project_auth


static func _is_auth_valid(auth: _GotmAuthData) -> bool:
	if !auth || auth.token.is_empty() || !(auth.expired > Time.get_unix_time_from_system() + 60):
		return false
	if !auth.project.is_empty() && auth.project_key != _Gotm.get_project_key():
		return false
	if _Gotm.get_singleton():
		var _global: _GotmAuthGlobalData = _GotmUtility.get_static_variable(_GotmAuth, "_global", _GotmAuthGlobalData.new())
		if auth.owner.is_empty() || !_global.gotm_auth || auth.owner != _global.gotm_auth.owner:
			return false
	return true


static func _read_auth(name: String) -> _GotmAuthData:
	var content := _GotmUtility.read_file(_Gotm.get_user_path(name))
	if content.is_empty():
		return null
	var parsed = JSON.parse_string(content)
	var auth := _format_auth_data(parsed.data)
	auth.project_key = parsed.project_key
	return auth


static func _refresh_auth(auth: _GotmAuthData) -> _GotmAuthData:
	var refreshed: _GotmAuthData = await _create_authentication({"refreshToken": auth.refresh_token})
	if !refreshed:
		return
	refreshed.project_key = auth.project_key
	return refreshed


static func _write_auth(auth: _GotmAuthData) -> void:
	if !auth:
		return
	var name := ""
	if auth.project:
		name = PROJECT_AUTH_NAME
	elif auth.is_guest:
		name = GUEST_AUTH_NAME
	else:
		return
	_GotmUtility.write_file(_Gotm.get_user_path(name), JSON.stringify({"data": auth.data, "project_key": auth.project_key}))


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


class _GotmAuthGlobalData:
	var auth: _GotmAuthData
#	var queue: _GotmUtility.QueueSignal
	var has_read_from_file := false
	var gotm_auth: _GotmAuthData


#static func _create_development_user_authentication() -> _GotmAuthData:
#	var email = "gdgotm@mail.com"
#	var result = await _GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/authentications/email?query=withCallbackUrl&callbackUrl=https://website.com&email=" + email)
#	if !result.ok || !(result.data.token is String):
#		return null
#	var sign_in_url = result.data.token
#	sign_in_url += "&email=" + email
#	return await _create_authentication({"signInUrl": sign_in_url})
