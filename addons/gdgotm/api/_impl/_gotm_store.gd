class_name _GotmStore


const _EVICTION_TIMEOUT_SECONDS = 5


static func _cached_get_request(path: String, authenticate: bool = false):
	if path.is_empty():
		return {}

	if path in _cache:
		var value = _cache[path]
		return value

	var value = await _request_data(path, HTTPClient.METHOD_GET, null, authenticate)
	if !value.is_empty():
		value = _set_cache(path, value)
		if value is Dictionary && value.get("data") is Array && value.get("next") is String:
			for resource in value.data:
				_set_cache(resource.path, resource)

	return value


static func clear_cache(path: String) -> void:
	for key in _cache.keys():
		if key == path || key.begins_with(path):
			_cache.erase(key)


static func create(api: String, data: Dictionary, _options: Dictionary = {}) -> Dictionary:
	var created: Dictionary = await _request_data(create_request_path(api, "", {}, {}), HTTPClient.METHOD_POST, data, true)
	if !created.is_empty():
		_set_cache(created.path, created)
	return created


static func create_request_path(path: String, query: String = "", params: Dictionary = {}, options: Dictionary = {}) -> String:
	var query_object := {}
	if query:
		query_object.query = query
		_GotmUtility.copy(params, query_object)
	if options.get("expand"):
		var expands = options.get("expand").keys()
		expands.sort()
		query_object.expand = ",".join(expands)
	return path + _GotmUtility.create_query_string(query_object)


static func delete(path) -> bool:
	var result := await _request(path, HTTPClient.METHOD_DELETE, null, true)
	if !result || !result.ok:
		return false
	_cache.erase(path)
	return true


static func fetch(path, query: String = "", params: Dictionary = {}, authenticate: bool = false, options: Dictionary = {}) -> Dictionary:
	return await _cached_get_request(create_request_path(path, query, params, options), authenticate)


static func fetch_blob(path, query: String = "", params: Dictionary = {}, authenticate: bool = false, options: Dictionary = {}) -> PackedByteArray:
	return await _cached_get_request(create_request_path(path, query, params, options), authenticate)


static func list(api: String, query: String, params: Dictionary = {}, authenticate: bool = false, options: Dictionary = {}) -> Array:
	var data: Dictionary = await _cached_get_request(create_request_path(api, query, params, options), authenticate)
	if data.is_empty() || !data.has("data"):
		return []
	return data.data


static func _request(path: String, method: int, body = null, authenticate: bool = false) -> _GotmUtility.FetchDataResult:
	if path.is_empty():
		return null
	var headers := {}
	if authenticate:
		var auth = _GotmAuth.get_auth()
		if !auth:
			auth = await _GotmAuth.get_auth_async()
		if !auth:
			return null
		headers.authorization = "Bearer " + auth.token

	if method != HTTPClient.METHOD_GET && method != HTTPClient.METHOD_HEAD && method != HTTPClient.METHOD_POST:
		match method:
			HTTPClient.METHOD_DELETE:
				headers.method = "DELETE"
			HTTPClient.METHOD_PATCH:
				headers.method = "PATCH"
			HTTPClient.METHOD_PUT:
				headers.method = "PUT"
		method = HTTPClient.METHOD_POST
	if !headers.is_empty():
		var header_string := ""
		for key in headers:
			header_string += key + ":" + headers[key] + "\n"
		var path_parts = path.split("?")
		if path_parts.size() < 2:
			path += "?"
		elif path_parts.size() > 2 || path_parts[1].length() > 0:
			path += "&"
		path += "$httpHeaders=" + _GotmUtility.encode_url_component(header_string)

	while !_take_rate_limiting_token():
		await _GotmUtility.get_tree().process_frame

	var result: _GotmUtility.FetchDataResult
	if path.begins_with(_Gotm.api_storage_origin):
		result = await _GotmUtility.fetch_data(path, method, body)
	elif path.begins_with("blobs/upload") && body.get("data") is PackedByteArray:
		body = body.duplicate()
		var data = body.data
		body.erase("data")
		var bytes = PackedByteArray()
		bytes += (JSON.stringify(body)).to_utf8_buffer()
		bytes.append(0)
		bytes += data
		result = await _GotmUtility.fetch_json(_Gotm.api_worker_origin + "/" + path, method, bytes)
	else:
		result = await _GotmUtility.fetch_json(_Gotm.api_origin + "/" + path, method, body)
	return result


static func _request_data(path: String, method: int, body = null, authenticate: bool = false):
	var request := await _request(path, method, body, authenticate)
	if !request || !request.ok:
		return {}
	return request.data


static func _set_cache(path: String, data):
	var existing_timer = _eviction_timers.get(path)
	_eviction_timers.erase(path)

	var eviction_timer_on_timeout = func(path: String) -> void:
		_cache.erase(path)

	if existing_timer is SceneTreeTimer:
		if (existing_timer as SceneTreeTimer).timeout.is_connected(Callable(eviction_timer_on_timeout)):
			(existing_timer as SceneTreeTimer).timeout.disconnect(Callable(eviction_timer_on_timeout))

	if data == null:
		_cache.erase(path)
		return null
	if data is Dictionary:
		for key in ["created", "updated", "expired"]:
			if key in data:
				data[key] = _GotmUtility.get_unix_time_from_iso(data[key])
	_cache[path] = data
	var timer := _GotmUtility.get_tree().create_timer(_EVICTION_TIMEOUT_SECONDS)
	timer.timeout.connect(Callable(eviction_timer_on_timeout).bind(path))
	_eviction_timers[path] = timer
	return data


static func _take_rate_limiting_token() -> bool:
	if !_token_bucket.has("count"):
		_token_bucket.capacity = 60
		_token_bucket.count = _token_bucket.capacity
		_token_bucket.fill_per_second = 2
		@warning_ignore("integer_division")
		_token_bucket.tick_seconds = Time.get_ticks_msec() / 1000

	@warning_ignore("integer_division")
	var tick_seconds = Time.get_ticks_msec() / 1000
	var fill = _token_bucket.fill_per_second * (tick_seconds - _token_bucket.tick_seconds)
	_token_bucket.count = min(_token_bucket.count + fill, _token_bucket.capacity)
	_token_bucket.tick_seconds = tick_seconds

	if _token_bucket.count <= 0:
		return false

	_token_bucket.count -= 1
	return true


static func update(path: String, data: Dictionary, options: Dictionary = {}) -> Dictionary:
	var updated: Dictionary = await _request_data(create_request_path(path, "", {}, options), HTTPClient.METHOD_PATCH, data, true)
	if !updated.is_empty():
		_set_cache(path, updated)
	return updated


static var _cache := {}
static var _eviction_timers := {}
static var _token_bucket := {}
