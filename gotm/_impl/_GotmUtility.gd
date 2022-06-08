class_name _GotmUtility


static func delete_null(dictionary: Dictionary) -> Dictionary:
	for key in dictionary:
		if dictionary[key] == null:
			dictionary.erase(key)
	return dictionary

static func copy(from, to):
	if not from or not to:
		return to
	for key in from:
		to[key] = from[key]
	return to


class FetchJsonResult:
	var code: String
	var data: Dictionary
	var headers: PoolStringArray
	var ok: bool

static func fetch_json(url: String, method: int, body = null, headers: PoolStringArray = []) -> FetchJsonResult:
	var request := HTTPRequest.new()
	get_tree().root.add_child(request)
	request.request(url, PoolStringArray(), true, method, "" if not body is Dictionary else to_json(body))
	var signal_results = yield(request, "request_completed")
	var result = signal_results[0] as int
	var code = signal_results[1] as int
	var response_headers = signal_results[2] as PoolStringArray
	var data = signal_results[3] as PoolByteArray
	return .copy({
		"code": code, 
		"data": parse_json(data.get_string_from_utf8()), 
		"headers": response_headers,
		"ok": code >= 200 && code <= 299
	}, FetchJsonResult.new())

static func create_query_string(dictionary: Dictionary) -> String:
	var string := ""
	var keys = dictionary.keys().sort()
	for i in range(0, keys.size()):
		var value = dictionary[keys[i]]
		if value is Object:
			value = to_json(value)
		string += encode_url_component(String(value))
		if i < keys.size() - 1:
			string += "&"
	if string:
		string = "?" + string
	return string

static func encode_url_component(string: String) -> String:
	var bytes: PoolByteArray = string.to_utf8()
	var encoded: String = ""
	for c in bytes:
		if c == 46 or c == 45 or c == 95 or c == 126 or (c >= 97 && c <= 122) or (c >= 65 && c <= 90) or (c >= 48 && c <= 57):
			encoded += char(c)
		else:
			encoded += "%%%02X" % [c]
	return encoded

static func get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


# Converts a date ISO string to UNIX epoch time in seconds.
static func get_unix_time_from_iso(iso: String) -> int:
	if not iso:
		return 0
	# TODO: Make sure it's seconds.
	return 0

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

