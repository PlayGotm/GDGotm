class_name _GotmUtility


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


static func coerce_resource_id(data, expected_api: String = ""):
	if !(data is Object || data is Dictionary || data is String):
		return data
	var id = data if data is String else data.get("id")
	if !(id is String):
		return data
	if !(id as String).is_empty() && !expected_api.is_empty() && !(id as String).begins_with(expected_api + "/"):
		push_error("[Gotm] Expected an id starting with '" + expected_api + "/', got '" + id + "'.")
		return null
	return id


static func copy(from, to):
	for key in _get_keys(from):
		to[key] = from[key]
	return to


static func create_id() -> String:
	var global := _get_global()
	var id: String = ""
	for i in range(20):
		id += global.id_chars[global.rng.randi() % global.id_chars.length()]
	return id


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
			value = str(value).to_lower()
		string += str(key) + "=" + str(value).replace("+", "%2B")
		if i < keys.size() - 1:
			string += "&"
	if string:
		string = "?" + string
	return string


static func create_resource_path(api: String) -> String:
	return api + "/" + create_id()


static func decode_cursor(cursor: String) -> Array:
	return JSON.parse_string(Marshalls.base64_to_utf8(cursor.replace("-", "+").replace("_", "/") + "=="))


static func decompress_gzip(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return PackedByteArray()
	var decompressed_size: int = data.size() * 2
	for i in range(0, 8):
		suppress_error_messages(true)
		var decompressed := data.decompress(decompressed_size, FileAccess.COMPRESSION_GZIP)
		suppress_error_messages(false)
		if !decompressed.is_empty():
			return decompressed
		decompressed_size *= 2
	return PackedByteArray()


static func delete_empty(dictionary: Dictionary) -> Dictionary:
	for key in dictionary.keys():
		if dictionary[key] == null:
			dictionary.erase(key)
			continue
		if dictionary[key] is String && dictionary[key] == "":
			dictionary.erase(key)
	return dictionary


static func delete_null(dictionary: Dictionary) -> Dictionary:
	for key in dictionary.keys():
		if dictionary[key] == null:
			dictionary.erase(key)
	return dictionary


static func encode_cursor(data: Array) -> String:
	return Marshalls.utf8_to_base64(JSON.stringify(data)).replace("=", "").replace("+", "-").replace("/", "_")


static func _encode_search_string(s: String) -> String:
	if s.is_empty():
		return s
	s = s.to_lower()
	var encoders: Array = _get_global().search_string_encoders
	for encoder in encoders:
		s = encoder[0].sub(s, encoder[1], true)
	return s


static func encode_url_component(string: String) -> String:
	var bytes: PackedByteArray = string.to_utf8_buffer()
	var encoded: String = ""
	for c in bytes:
		if c == 46 || c == 45 || c == 95 || c == 126 || (c >= 97 && c <= 122) || (c >= 65 && c <= 90) || (c >= 48 && c <= 57):
			encoded += char(c)
		else:
			encoded += "%%%02X" % [c]
	return encoded


static func fetch_data(url: String, method: int = HTTPClient.METHOD_GET, body = null, headers: PackedStringArray = []) -> FetchDataResult:
	var parsed_url := parse_url(url)
	var origin = parsed_url.origin
	var host = parsed_url.host
	var port = parsed_url.port
	var path = parsed_url.path

	var free_clients = _get_global().free_http_clients.get(origin)
	if !(free_clients is Array):
		free_clients = []
		_get_global().free_http_clients[origin] = free_clients

	var client: HTTPClient = free_clients.pop_back() if free_clients else HTTPClient.new()
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.connect_to_host(host, port) # TODO: function changed, is SSL/TSL ok like this (compared to prior)?
		client.poll()

	var has_yielded := false
	while client.get_status() == HTTPClient.STATUS_CONNECTING || client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		has_yielded = true
		await get_tree().process_frame

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		free_clients.append(client)
		if !has_yielded:
			await get_tree().process_frame
		return

	if body is Dictionary:
		body = JSON.stringify(body)
	elif body is PackedByteArray:
		pass
	else:
		body = ""

	if body is PackedByteArray:
		client.request_raw(method, path, headers, body)
	else:
		client.request(method, path, headers, body)
	client.poll()
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		await get_tree().process_frame
		client.poll()

	var response = copy(delete_null({
		"code": client.get_response_code(),
		"data": PackedByteArray(),
		"headers": client.get_response_headers_as_dictionary(),
		"ok": client.get_response_code() >= 200 && client.get_response_code() <= 299
	}), FetchDataResult.new())

	while client.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
		client.poll()
		# Get a chunk.
		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			await get_tree().process_frame
		else:
			response.data += chunk

	free_clients.append(client)
	if !has_yielded:
		await get_tree().process_frame
	if OS.get_name () != "HTML5" && response.headers.get("content-encoding") == "gzip":
		response.data = decompress_gzip(response.data)
	return response


static func fetch_json(url: String, method: int = HTTPClient.METHOD_GET, body = null, headers: PackedStringArray = []) -> FetchDataResult:
	var result = await fetch_data(url, method, body, headers)
	var data_string = result.data.get_string_from_utf8()
	result.data = JSON.parse_string(data_string) if data_string else {}
	return result


static func _fuzzy_compare(a, b, compare_less: bool) -> bool:
	if a == null || b == null:
		return false

	if typeof(a) == typeof(b):
		return a < b if compare_less else a > b

	# GDScript doesn't handle comparison of different types very well.
	# Try Array's min() and max()
	var m = [a, b].min() if compare_less else [a, b].max()
	if m != null:
		return m == a

	# Default to string converion
	a = str(a)
	b = str(b)
	return a < b if compare_less else a > b


static func get_engine_unix_time() -> int:
	var global := _get_global()
	return global.start_unix_time + Time.get_ticks_msec() - global.start_ticks


static func _get_global() -> GlobalData:
	var _global = get_static_variable(_GotmUtility, "_global", null)
	if !_global:
		_global = GlobalData.new()
		set_static_variable(_GotmUtility, "_global", _global)
	return _global


# Converts UNIX epoch time in milliseconds to a date ISO 8601 string.
static func get_iso_from_unix_time(unix_time_ms: int = get_engine_unix_time()) -> String:
	@warning_ignore("integer_division")
	var datetime = Time.get_datetime_dict_from_unix_time(unix_time_ms / 1000)
	return "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute, datetime.second, unix_time_ms % 1000]


static func _get_keys(object) -> Array:
	if object == null || !(object is Array || object is Dictionary || object is Object):
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


static func get_last_element(array: Array):
	return array.back()


static func get_nested_value(path_or_parts, object, undefined_value = null, path_index: int = 0):
	var parts: Array = path_or_parts if path_or_parts is Array || path_or_parts is PackedStringArray else path_or_parts.split("/")
	if path_index >= parts.size():
		return undefined_value
	var part = parts[path_index]
	if object is Array:
		if str(int(part)) != part:
			return undefined_value
		part = int(part)
	for key in _get_keys(object):
		if key != part:
			continue
		if path_index + 1 >= parts.size():
			return object[key]
		return get_nested_value(parts, object[key], undefined_value, path_index + 1)
	return undefined_value


static func get_static_variable(script: Script, name: String, default_value):
	if script.has_meta(name):
		return script.get_meta(name)
	if default_value == null:
		return null
	script.set_meta(name, default_value)
	return script.get_meta(name)


static func get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func get_unix_offset() -> int:
	var local_unix = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	var unix = Time.get_unix_time_from_system()
	var offset = local_unix - unix
	return offset * 1000


# Converts a date ISO 8601 string to UNIX epoch time in milliseconds.
static func get_unix_time_from_iso(iso: String) -> int:
	if iso.is_empty():
		return 0
	return Time.get_unix_time_from_datetime_string(iso)


static func is_fuzzy_equal(a, b) -> bool:
	return !is_less(a, b) && !is_greater(a, b)


static func is_greater(a, b) -> bool:
	return _fuzzy_compare(a, b, false)


static func is_less(a, b) -> bool:
	return _fuzzy_compare(a, b, true)


static func is_partial_search_match(query: String, string: String) -> bool:
	query = _encode_search_string(query)
	if query.is_empty():
		return true
	string = _encode_search_string(string)
	if string.is_empty():
		return false
	var query_parts: Array = query.split(" ", false)
	for part in query_parts:
		if string.find(part) < 0:
			return false
	return true


static func is_strictly_equal(a, b) -> bool:
	return typeof(a) == typeof(b) && a == b


static func join(array: Array, separator: String = ",") -> String:
	var string = ""
	for i in range(0, array.size()):
		string += array[i]
		if i < array.size() - 1:
			string += separator
	return string


static func parse_url(url: String) -> Dictionary:
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


static func read_file(path: String) -> String:
	if !FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Gotm FileAccess Error " + str(FileAccess.get_open_error()) +"] Cannot open file at path: ", path)
		return ""

	var content := file.get_as_text() if file.is_open() else ""
	file.close()
	return content


static func read_file_as_binary(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Gotm FileAccess Error " + str(FileAccess.get_open_error()) +"] Cannot open file at path: ", path)
		return PackedByteArray()

	var content := file.get_buffer(file.get_length()) if file.is_open() else PackedByteArray()
	file.close()
	return content


static func set_static_variable(script: Script, name: String, value) -> void:
	script.set_meta(name, value)


static func suppress_error_messages(suppress: bool) -> void:
	Engine.print_error_messages = !suppress


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
	return JSON.stringify(value)


static func write_file(path: String, data) -> void:
	if !(data == null || data is String || data is PackedByteArray):
		push_error("[Gotm] Data expected to be either null, String, or PackedByteArray.")
		return

	if data == null:
		DirAccess.remove_absolute(path)
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		file = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("[Gotm FileAccess Error " + str(FileAccess.get_open_error()) +"] Cannot open file at path: ", path)
			return

	if file.is_open():
		if data is String:
			file.store_string(data)
		else:
			file.store_buffer(data)
	file.close()

# TODO: See if needed after testing GotmAuth
#class FakeSignal:
#	signal completed()


class FetchDataResult:
	var code: int
	var data
	var headers: Dictionary
	var ok: bool


class GlobalData:
	var id_chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var rng := RandomNumberGenerator.new()
	var search_string_encoders := _create_search_string_encoders()
	var free_http_clients := {}
	var start_unix_time = Time.get_unix_time_from_system() * 1000
	var start_ticks = Time.get_ticks_msec()

	func _init() -> void:
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

# TODO: See if needed after testing GotmAuth
#class QueueSignal:
#	var _queue := []
#
#	func add() -> FakeSignal:
#		var sig = FakeSignal.new()
#		_queue.append(sig)
#		return sig
#
#	func trigger() -> void:
#		var queue = _queue
#		_queue = []
#		for sig in queue:
#			sig.emit_signal("completed")
