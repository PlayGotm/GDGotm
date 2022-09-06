class_name _GotmStore
#warnings-disable

static func create(api, data: Dictionary, options: Dictionary = {}) -> Dictionary:
	var created = yield(_request(create_request_path(api, "", {}, {}), HTTPClient.METHOD_POST, data, true), "completed")
	if created:
		_set_cache(created.path, created)
	return created

static func update(path, data: Dictionary, options: Dictionary = {}) -> Dictionary:
	var updated = yield(_request(create_request_path(path, "", {}, options), HTTPClient.METHOD_PATCH, data, true), "completed")
	if updated:
		_set_cache(path, updated)
	return updated

static func delete(path) -> void:
	yield(_request(path, HTTPClient.METHOD_DELETE, null, true), "completed")
	_cache.erase(path)
	
static func fetch(path, query: String = "", params: Dictionary = {}, authenticate: bool = false, options: Dictionary = {}) -> Dictionary:
	return yield(_cached_get_request(create_request_path(path, query, params, options), authenticate), "completed")

static func list(api, query: String, params: Dictionary = {}, authenticate: bool = false, options: Dictionary = {}) -> Array:
	var data = yield(_cached_get_request(create_request_path(api, query, params, options), authenticate), "completed")
	if !data || !data.data:
		return
	return data.data

const _cache = {}
const _signal_cache = {}
const _eviction_timers = {}
const _eviction_timeout_seconds = 5

static func clear_cache(path: String) -> void:
	for key in _cache.keys():
		if key == path || key.begins_with(path):
			_cache.erase(key)

class EvictionTimerHandler:
	static func on_timeout(path: String):
		_cache.erase(path)

static func create_request_path(path: String, query: String = "", params: Dictionary = {}, options: Dictionary = {}) -> String:
	var query_object := {}
	if query:
		query_object.query = query
		_GotmUtility.copy(params, query_object)
	if options.get("expand"):
		var expands = options.get("expand").keys()
		expands.sort()
		query_object.expand = expands.join(",")
	return path + _GotmUtility.create_query_string(query_object)

static func _set_cache(path: String, data):
	var existing_timer = _eviction_timers.get(path)
	_eviction_timers.erase(path)
	if existing_timer is SceneTreeTimer:
		existing_timer.disconnect("timeout", EvictionTimerHandler, "on_timeout")
	
	if !data:
		_cache.erase(path)
		return
	if data is Dictionary:
		for key in ["created", "updated", "expired"]:
			if key in data:
				data[key] = _GotmUtility.get_unix_time_from_iso(data[key])
	_cache[path] = data
	var timer := _GotmUtility.get_tree().create_timer(_eviction_timeout_seconds)
	timer.connect("timeout", EvictionTimerHandler, "on_timeout", [path])
	_eviction_timers[path] = timer
	return data

static func _cached_get_request(path: String, authenticate: bool = false) -> Dictionary:
	if !path:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	
	if path in _cache:
		var value = _cache[path]
		yield(_GotmUtility.get_tree(), "idle_frame")
		return value
	
	if path in _signal_cache:
		yield(_signal_cache[path].add(), "completed")
		return _cache[path]
	
	
	var queue_signal = _GotmUtility.QueueSignal.new()
	_signal_cache[path] = queue_signal
	var value = yield(_request(path, HTTPClient.METHOD_GET, null, authenticate), "completed")
	if value:
		value = _set_cache(path, value)
		if value is Dictionary && value.get("data") is Array && value.get("next") is String:
			for resource in value.data:
				_set_cache(resource.path, resource)
		
	_signal_cache.erase(path)
	queue_signal.trigger()
	return value


const _token_bucket := {}
static func _take_rate_limiting_token() -> bool:
	if !_token_bucket.has("count"):
		_token_bucket.capacity = 60
		_token_bucket.count = _token_bucket.capacity
		_token_bucket.fill_per_second = 2
		_token_bucket.tick_seconds = OS.get_ticks_msec() / 1000
	
	var tick_seconds = OS.get_ticks_msec() / 1000
	var fill = _token_bucket.fill_per_second * (tick_seconds - _token_bucket.tick_seconds)
	_token_bucket.count = min(_token_bucket.count + fill, _token_bucket.capacity)
	_token_bucket.tick_seconds = tick_seconds
	
	if _token_bucket.count <= 0:
		return false
	
	_token_bucket.count -= 1
	return true

static func _request(path, method: int, body = null, authenticate: bool = false) -> Dictionary:
	if !path:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return
	var headers := {}
	if authenticate:
		var auth = _GotmAuth.get_auth()
		if !auth:
			auth = yield(_GotmAuth.get_auth_async(), "completed")
		if !auth:
			return
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
	if !headers.empty():
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
		yield(_GotmUtility.get_tree(), "idle_frame")
	
	var result
	if path.begins_with(_Gotm.get_global().storageApiEndpoint):
		result = yield(_GotmUtility.fetch_data(path, method, body), "completed")
	elif path.begins_with("blobs/upload") && body.get("data") is PoolByteArray:
		body = body.duplicate()
		var data = body.data
		body.erase("data")
		var bytes = PoolByteArray()
		bytes += (to_json(body)).to_utf8()
		bytes.append(0)
		bytes += data
		result = yield(_GotmUtility.fetch_json(_Gotm.get_global().apiWorkerOrigin + "/" + path, method, bytes), "completed")
	else:
		result = yield(_GotmUtility.fetch_json(_Gotm.get_global().apiOrigin + "/" + path, method, body), "completed")
	if !result.ok:
		return
	return result.data
