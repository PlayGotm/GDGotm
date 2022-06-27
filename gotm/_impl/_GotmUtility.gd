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
	if !from:
		return to
	var keys:= []
	if from is Array:
		keys = range(0, from.size())
	elif from is Dictionary:
		keys = from.keys()
	else:
		var properties = from.get_property_list()
		for property in properties:
			if property.usage == PROPERTY_USAGE_SCRIPT_VARIABLE:
				keys.append(property.name)
	for key in keys:
		to[key] = from[key]
	return to


class FetchJsonResult:
	var code: int
	var data: Dictionary
	var headers: PoolStringArray
	var ok: bool

static func encode_cursor(data: Array) -> String:
	return Marshalls.utf8_to_base64(to_json(data)).replace("=", "").replace("+", "-").replace("/", "_")

static func decode_cursor(cursor: String) -> Array:
	return parse_json(Marshalls.base64_to_utf8(cursor.replace("-", "+").replace("_", "/") + "=="))

static func fetch_json(url: String, method: int, body = null, headers: PoolStringArray = []) -> FetchJsonResult:
	var request := HTTPRequest.new()
	if get_tree().get_frame() <= 0:
		yield(get_tree(), "idle_frame")
	get_tree().root.add_child(request)
	var error = request.request(url, headers, true, method, "" if !(body is Dictionary) else to_json(body))
	var signal_results = yield(request, "request_completed")
	var result = signal_results[0] as int
	var code = signal_results[1] as int
	var response_headers = signal_results[2] as PoolStringArray
	var data = signal_results[3] as PoolByteArray
	var data_string = data.get_string_from_utf8()
	return copy(delete_null({
		"code": code, 
		"data": parse_json(data_string) if data_string else {}, 
		"headers": response_headers,
		"ok": code >= 200 && code <= 299
	}), FetchJsonResult.new())

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

# Converts UNIX epoch time in milliseconds to a date ISO 8601 string.
static func get_iso_from_unix_time(unix_time_ms: int = OS.get_unix_time() * 1000 + OS.get_ticks_msec() % 1000) -> String:
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
	
	func _init():
		rng.randomize()

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
