class_name _GotmUtility
#warnings-disable




static func delete_null(dictionary: Dictionary) -> Dictionary:
	for key in dictionary.keys():
		if dictionary[key] == null:
			dictionary.erase(key)
	return dictionary

static func delete_empty(dictionary: Dictionary) -> Dictionary:
	for key in dictionary.keys():
		if !dictionary[key]:
			dictionary.erase(key)
	return dictionary

static func copy(from, to):
	for key in _get_keys(from):
		to[key] = from[key]
	return to

static func _get_keys(object) -> Array:
	if !object || object is float || object is bool || object is int:
		return []
	
	if object is Array:
		return range(0, object.size())
	if object is Dictionary:
		return object.keys()
	
	var keys := []
	var properties = object.get_property_list()
	for property in properties:
		if property.usage == PROPERTY_USAGE_SCRIPT_VARIABLE:
			keys.append(property.name)
	return keys

static func coerce_resource_id(data, expected_api = ""):
	if !(data is Object) && !(data is Dictionary) && !(data is String):
		return data
	var id = data if data is String else data.get("id")
	if !(id is String):
		return data
	if id && expected_api && !id.begins_with(expected_api + "/"):
		push_error("Expected an id starting with '" + expected_api + "/', got '" + id + "'.")
		return
	return id



class FetchDataResult:
	var code: int
	var data
	var headers: Dictionary
	var ok: bool

static func encode_cursor(data: Array) -> String:
	return Marshalls.utf8_to_base64(to_json(data)).replace("=", "").replace("+", "-").replace("/", "_")

static func decode_cursor(cursor: String) -> Array:
	return parse_json(Marshalls.base64_to_utf8(cursor.replace("-", "+").replace("_", "/") + "=="))


static func parse_url(url: String):
	var url_parts = url.split("/")
	var origin = url_parts[0] + "//" + url_parts[2]
	var origin_parts = origin.split(":")
	var host = origin_parts[0] + ":" + origin_parts[1]
	var port = int(origin_parts[2]) if origin_parts.size() > 2 else -1
	var path = url.replace(origin, "")
	var query_index = path.find("?")
	var pathname = path
	var query = ""
	if query_index >= 0:
		pathname = path.substr(0, query_index)
		query = path.substr(query_index, path.length()).replace(" ", "%20")
	return {"origin": origin, "host": host, "port": port, "pathname": pathname, "query": query, "path": pathname + query}
	

static func fetch_data(url: String, method: int = HTTPClient.METHOD_GET, body = null, headers: PoolStringArray = []) -> FetchDataResult:
	var parsed_url = parse_url(url)
	var origin = parsed_url.origin
	var host = parsed_url.host
	var port = parsed_url.port
	var path = parsed_url.path
	
	
	var free_clients = _get_global().free_http_clients.get(origin)
	if !(free_clients is Array):
		free_clients = []
		_get_global().free_http_clients[origin] = free_clients
	var client: HTTPClient = free_clients.pop_back() if free_clients else HTTPClient.new()
	
	var is_localhost = host == "http://localhost"
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.connect_to_host(host, port, !is_localhost, !is_localhost) 
		client.poll()
	
	var has_yielded := false
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		has_yielded = true
		yield(get_tree(), "idle_frame")
	
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		free_clients.append(client)
		if !has_yielded:
			yield(get_tree(), "idle_frame")
		return
	
	if body is Dictionary:
		body = to_json(body)
	elif body is PoolByteArray:
		pass
	else:
		body = ""

	if body is PoolByteArray:
		client.request_raw(method, path, headers, body)
	else:
		client.request(method, path, headers, body)
	client.poll()
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		yield(get_tree(), "idle_frame")
		client.poll()
		
	var status = client.get_status() 
	var response = copy(delete_null({
		"code": client.get_response_code(),
		"data": PoolByteArray(),
		"headers": client.get_response_headers_as_dictionary(),
		"ok": client.get_response_code() >= 200 && client.get_response_code() <= 299
	}), FetchDataResult.new())
	while client.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
		client.poll()
		# Get a chunk.
		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			yield(get_tree(), "idle_frame")
		else:
			response.data += chunk
	
	free_clients.append(client)
	if !has_yielded:
		yield(get_tree(), "idle_frame")
	if OS.get_name () != "HTML5" && response.headers.get("content-encoding") == "gzip":
		response.data = decompress_gzip(response.data)
	return response


## Only supported in 3.4.0 and later.
static func suppress_error_messages(suppress: bool) -> void:
	Engine.set("print_error_messages", !suppress)

static func decompress_gzip(data: PoolByteArray) -> PoolByteArray:
	if data.empty():
		return PoolByteArray()
	var decompressed_size: int = data.size() * 2
	for i in range(0, 8):
		suppress_error_messages(true)
		var decompressed := data.decompress(decompressed_size, File.COMPRESSION_GZIP)
		suppress_error_messages(false)
		if !decompressed.empty():
			return decompressed
		decompressed_size *= 2
	
	return PoolByteArray()


static func fetch_json(url: String, method: int = HTTPClient.METHOD_GET, body = null, headers: PoolStringArray = []) -> FetchDataResult:
	var result = yield(fetch_data(url, method, body, headers), "completed")
	var data_string = result.data.get_string_from_utf8()
	result.data = parse_json(data_string) if data_string else {}
	return result

static func clean_for_json(value):
	if value is float:
		if is_nan(value):
			return 0.0
		if is_inf(value):
			return 9007199254740991.0 if value >= 0 else -9007199254740991.0
		return value
		
	if value is Array:
		value = value.duplicate()
		for i in range(0, value.size()):
			value[i] = clean_for_json(value[i])
		return value
	if value is Dictionary:
		value = value.duplicate()
		for key in value:
			value[key] = clean_for_json(value[key])
		return value
	return value


class DeferredSignal:
	var is_completed := false
	var value
	var _signal
	var tree: SceneTree
	class Yieldable:
		signal completed()
	func get_yieldable() -> Yieldable:
		if is_completed:
			yield(tree, "idle_frame")
			return value
		else:
			return _signal
		
	func _on_completed(v):
		value = v
		is_completed = true
		

static func get_yieldable(sig):
	return yield(defer_signal(sig).get_yieldable(), "completed")

static func defer_signal(sig) -> DeferredSignal:
	var deferred := DeferredSignal.new()
	deferred.tree = get_tree()
	if !(sig is GDScriptFunctionState):
		deferred.is_completed = true
		deferred.value = sig
		return deferred
	deferred._signal = sig
	sig.connect("completed", deferred, "_on_completed")
	return deferred


static func create_query_string(dictionary: Dictionary) -> String:
	var string := ""
	var keys = dictionary.keys()
	keys.sort()
	for i in range(0, keys.size()):
		var key = keys[i]
		var value = dictionary[key]
		if value is Object || value is Dictionary || value is Array:
			value = to_stable_json(value)
		elif value is bool:
			value = String(value).to_lower()
		string += String(key) + "=" + String(value)
		if i < keys.size() - 1:
			string += "&"
	if string:
		string = "?" + string
	return string

static func get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


# Converts a date ISO 8601 string to UNIX epoch time in milliseconds.
static func get_unix_time_from_iso(iso: String) -> int:
	if !iso:
		return 0
	var date := iso.split("T")[0].split("-")
	var time := iso.split("T")[1].trim_suffix("Z").split(":")
	var datetime = {
		year = date[0],
		month = date[1],
		day = date[2],
		hour = time[0],
		minute = time[1],
		second = time[2],
	}
	var milliseconds = int(time[2].split(".")[1])
	return OS.get_unix_time_from_datetime(datetime) * 1000 + milliseconds

static func encode_url_component(string: String) -> String:
	var bytes: PoolByteArray = string.to_utf8()
	var encoded: String = ""
	for c in bytes:
		if c == 46 or c == 45 or c == 95 or c == 126 or (c >= 97 && c <= 122) or (c >= 65 && c <= 90) or (c >= 48 && c <= 57):
			encoded += char(c)
		else:
			encoded += "%%%02X" % [c]
	return encoded

static func get_engine_unix_time() -> int:
	var global := _get_global()
	return global.start_unix_time + OS.get_ticks_msec() - global.start_ticks
	

# Converts UNIX epoch time in milliseconds to a date ISO 8601 string.
static func get_iso_from_unix_time(unix_time_ms: int = get_engine_unix_time()) -> String:
	var datetime = OS.get_datetime_from_unix_time(unix_time_ms / 1000)
	return "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second, unix_time_ms % 1000]

static func join(array: Array, separator: String = ",") -> String:
	var string = ""
	for i in range(0, array.size()):
		string += array[i]
		if i < array.size() - 1:
			string += separator
	return string

static func get_unix_offset() -> int:
	var local_unix = OS.get_unix_time_from_datetime(OS.get_datetime())
	var unix = OS.get_unix_time() 
	var offset = local_unix - unix
	return offset * 1000

static func to_stable_json(value) -> String:
	if value is Array:
		var child_strings := []
		for child in value:
			child_strings.append(to_stable_json(child))
		return "[" + join(child_strings, ",") + "]"
	if value is Dictionary:
		var keys = value.keys()
		keys.sort()
		var child_strings := []
		for key in keys:
			child_strings.append("\"" + key + "\":" + to_stable_json(value[key]))
		return "{" + join(child_strings, ",") + "}"
	return to_json(value)


const _global = {"value": null}
class GlobalData:
	var id_chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var rng := RandomNumberGenerator.new()
	var search_string_encoders := _create_search_string_encoders()
	var free_http_clients := {}
	var start_unix_time = OS.get_unix_time() * 1000
	var start_ticks = OS.get_ticks_msec()
	
	func _init():
		rng.randomize()
	
	# Simplify string somewhat. We want exact matches, but with some reasonable fuzziness.
	func _create_search_string_encoders() -> Array:
		var encoders: Array = [
			["[àáâãäå]", "a"],
			["[èéêë]", "e"],
			["[ìíîï]", "i"],
			["[òóôõöő]", "o"],
			["[ùúûüű]", "u"],
			["[ýŷÿ]", "y"],
			["ñ", "n"],
			["[çc]", "k"],
			["ß", "s"],
			["[-/]", " "],
			["[^a-z0-9 ]", ""],
			["\\s+", " "],
			["^\\s+", ""],
			["\\s+$", ""]
		]
		for encoder in encoders:
			var regex: RegEx = RegEx.new()
			regex.compile(encoder[0])
			encoder[0] = regex
		
		return encoders

static func _get_global() -> GlobalData:
	var value = _global.value
	if !value:
		value = GlobalData.new()
		_global.value = value
	return value

static func create_id() -> String:
	var global := _get_global()
	var id: String = ""
	for i in range(20):
		id += global.id_chars[global.rng.randi() % global.id_chars.length()]
	return id

static func create_resource_path(api: String) -> String:
	return api + "/" + create_id()

class FakeSignal:
	signal completed()

class QueueSignal:
	var _queue := []
	
	func trigger() -> void:
		var queue = _queue
		_queue = []
		for sig in queue:
			sig.emit_signal("completed")
			
		
	func add() -> FakeSignal:
		var sig = FakeSignal.new()
		_queue.append(sig)
		return sig



# Improve search experience a little by adding fuzziness.
static func _encode_search_string(s: String) -> String:
	if !s:
		return s
	s = s.to_lower()
	var encoders: Array = _get_global().search_string_encoders
	for encoder in encoders:
		s = encoder[0].sub(s, encoder[1], true)
	return s

static func is_partial_search_match(query: String, string: String) -> bool:
	query = _encode_search_string(query)
	if !query:
		return true
	string = _encode_search_string(string)
	if !string:
		return false
	var query_parts: Array = query.split(" ", false)
	for part in query_parts:
		if string.find(part) < 0:
			return false
	return true

static func _fuzzy_compare(a, b, compare_less: bool) -> bool:
	if typeof(a) == typeof(b):
		return a < b if compare_less else a > b
		
	# GDScript doesn't handle comparison of different types very well.
	# Abuse Array's min and max functions instead.
	var m = [a, b].min() if compare_less else [a, b].max()
	if m != null || a == null || b == null:
		return m == a
			
	# Array method failed. Go with strings instead.
	a = String(a)
	b = String(b)
	return a < b if compare_less else a > b

static func is_strictly_equal(a, b) -> bool:
	return typeof(a) == typeof(b) && a == b

static func is_fuzzy_equal(a, b) -> bool:
	return !is_less(a, b) && !is_greater(a, b)

static func is_less(a, b) -> bool:
	return _fuzzy_compare(a, b, true)


static func is_greater(a, b) -> bool:
	return _fuzzy_compare(a, b, false)

static func get_last_element(array):
	if !array || !(array is Array):
		return
	return array[array.size() - 1]

static func write_file(path: String, data):
	if data == null:
		Directory.new().remove(path)
		return
	
	var file := File.new()
	file.open(path, File.WRITE)
	if !file.is_open():
		var directory := Directory.new()
		directory.make_dir_recursive(path.get_base_dir())
		file.open(path, File.WRITE)
	if file.is_open():
		if data is String:
			file.store_string(data)
		else:
			file.store_buffer(data)
	file.close()

static func read_file(path: String, as_binary: bool = false):
	var file := File.new()
	file.open(path, File.READ)
	var content
	if as_binary:
		content = file.get_buffer(file.get_len()) if file.is_open() else PoolByteArray()
	else:
		content = file.get_as_text() if file.is_open() else ""
	file.close()
	return content
	
static func get_nested_value(path_or_parts, object, undefined_value = null, path_index: int = 0):
	var parts: Array = path_or_parts if path_or_parts is Array || path_or_parts is PoolStringArray else path_or_parts.split("/")
	if path_index >= parts.size():
		return undefined_value
	var part = parts[path_index]
	if object is Array:
		if String(int(part)) != part:
			return undefined_value
		part = int(part)
	
	for key in _get_keys(object):
		if key != part:
			continue
		if path_index + 1 >= parts.size():
			return object[key]
		return get_nested_value(parts, object[key], undefined_value, path_index + 1)
	return undefined_value
