class_name _GotmAuth


const GUEST_AUTH_NAME := "guest_auth.json"
const PROJECT_AUTH_NAME := "project_auth.json"


static func _create_authentication(body: Dictionary = {}, headers: PackedStringArray = []) -> _GotmAuthData:
	var result = await _GotmUtility.fetch_json(_Gotm.api_origin + "/authentications", HTTPClient.METHOD_POST, body, headers)
	if !result.ok:
		return null
	return _format_auth_data(result.data)


static func fetch() -> GotmAuth:
	var auth = await get_auth_async()
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
	var parsed_token := _parse_token(data.token)
	auth.project = parsed_token.get("project", "")
	auth.instance = parsed_token.get("instance", "")
	auth.expired = _GotmUtility.get_unix_time_from_iso(data.expired)
	return auth


static func get_auth() -> _GotmAuthData:
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


static var _auth_promise: _GotmUtility.ResolvablePromise
static func get_auth_async() -> _GotmAuthData:
	var auth = get_auth()
	if auth:
		return auth
	if _auth_promise:
		await _auth_promise
		return get_auth()

	var promise := _GotmUtility.ResolvablePromise.new()
	_auth_promise = promise
	auth = await _get_refreshed_project_auth(_global.auth)
	_write_auth(auth)
	_global.auth = auth

	_auth_promise = null
	promise.resolve()
	return get_auth()



static func _parse_token(token: String) -> Dictionary:
	if token.is_empty():
		return {}
	var parts = token.split(".")
	if parts.size() != 3:
		return {}
	var data: Dictionary = JSON.parse_string(Marshalls.base64_to_utf8(parts[1] + "=="))
	return data if data else {}


static func _get_refreshed_project_auth(auth: _GotmAuthData) -> _GotmAuthData:
	var project_key := Gotm.project_key
	if project_key.is_empty():
		return null
	if auth && !auth.refresh_token.is_empty() && !auth.project.is_empty() && !auth.project_key.is_empty() && auth.project_key == project_key:
		var data = await _refresh_auth(auth)
		if data:
			return data

	var user_auth: _GotmAuthData
#	if _Gotm.api_origin.begins_with("http://localhost"):
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
	if !auth || auth.token.is_empty() || !(auth.expired > (Time.get_unix_time_from_system() + 60) * 1000):
		return false
	if !auth.project.is_empty() && auth.project_key != Gotm.project_key:
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
	var instance: String


class _GotmAuthGlobalData:
	var auth: _GotmAuthData
#	var queue: _GotmUtility.QueueSignal
	var has_read_from_file := false

static var _global := _GotmAuthGlobalData.new()



#static func _create_development_user_authentication() -> _GotmAuthData:
#	var email = "gdgotm@mail.com"
#	var result = await _GotmUtility.fetch_json(_Gotm.api_origin + "/authentications/email?query=withCallbackUrl&callbackUrl=https://website.com&email=" + email)
#	if !result.ok || !(result.data.token is String):
#		return null
#	var sign_in_url = result.data.token
#	sign_in_url += "&email=" + email
#	return await _create_authentication({"signInUrl": sign_in_url})
