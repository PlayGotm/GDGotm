class_name _GotmImpl
#warnings-disable

# Utility sorter for 'sort_custom'.
class LobbySorter:
	var fetch
	var g
	
	func sort(lhs, rhs) -> bool:
		var a
		var b
		if fetch.sort_property.empty():
			a = lhs._impl.created
			b = rhs._impl.created
		else:
			a = lhs._impl.props[fetch.sort_property]
			b = rhs._impl.props[fetch.sort_property]
		
		
		if typeof(a) == typeof(b):
			return a < b if fetch.sort_ascending else a > b
		
		# GDScript doesn't handle comparison of different types very well.
		# Abuse Array's min and max functions instead.
		var m = [a, b].min() if fetch.sort_ascending else [a, b].max()
		if m != null or a == null or b == null:
			return m == a
			
		# Array method failed. Go with strings instead.
		a = String(a)
		b = String(b)
		return a < b if fetch.sort_ascending else a > b


# Generate 20 characters long random string.
static func _generate_id() -> String:
	var g = _get_gotm()
	var id: String = ""
	for i in range(20):
		id += g._impl.chars[g._impl.rng.randi() % g._impl.chars.length()]
	return id


# Retrieve scene statically via Engine singleton.
static func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


# Get autoloaded Gotm instance from scene's root.
static func _get_gotm() -> Node:
	return _get_tree().root.get_node("Gotm")


# Simplify string somewhat. We want exact matches, but with some reasonable fuzziness.
static func _init_search_string_encoders() -> Array:
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


# Attach some global state to autoloaded Gotm instance.
static func _initialize() -> void:
	var g = _get_gotm()
		
	g._impl = {
		"lobbies": [],
		"chars": "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-",
		"rng": RandomNumberGenerator.new(),
		"last_lobby_created": 0,
		"search_string_encoders": _init_search_string_encoders()
	}
	g._impl.rng.randomize()


# Improve search experience a little by adding fuzziness.
static func _encode_search_string(s: String) -> String:
	s = s.to_lower()
	var encoders: Array = _get_gotm()._impl.search_string_encoders
	for encoder in encoders:
		s = encoder[0].sub(s, encoder[1], true)
	return s


# Return true if 'lobby' matches filter options in 'fetch'.
static func _match_lobby(lobby, fetch) -> bool:
	if lobby.locked or lobby.hidden:
		return false
	
	if not fetch.filter_name.empty():
		var name: String = _encode_search_string(lobby.name)
		var query: String = _encode_search_string(fetch.filter_name)
		if not query.empty() and name.find(query) < 0:
			return false
	
	var lobby_props: Dictionary = {}
	for key in lobby._impl.filterable_props:
		if not lobby._impl.props.has(key):
			return false
		if not fetch.filter_properties.has(key):
			return false
		
		var lhs = fetch.filter_properties[key]
		var rhs = lobby._impl.props[key]
		if lhs != null and lhs != rhs:
			return false
		
	return true


# Used to detect changes.
static func _stringify_fetch_state(fetch) -> String:
	var d: Array = [
		fetch.filter_name,
		fetch.filter_properties,
		fetch.sort_property,
		fetch.sort_property,
		fetch.sort_ascending
	]
	return JSON.print(d)
	


# Return sorted copy of 'lobbies' using sort options in 'fetch'.
static func _sort_lobbies(lobbies: Array, fetch) -> Array:
	var sorted: Array = []
	var g = _get_gotm()
	for lobby in lobbies:
		if fetch.sort_property.empty() or lobby._impl.props.has(fetch.sort_property):
			sorted.push_back(lobby)
	
	var sorter: LobbySorter = LobbySorter.new()
	sorter.fetch = fetch
	sorter.g = g
	sorted.sort_custom(sorter, "sort")
	
	return sorted	


static func _fetch_lobbies(fetch, count: int, type: String) -> Array:
	var g = _get_gotm()
	
	# Reset fetch state if user has modified any options.
	var stringified_state: String = _stringify_fetch_state(fetch)
	if not fetch._impl.has("last_state") or stringified_state != fetch._impl.last_state:
		fetch._impl.last_state = stringified_state
		fetch._impl.last_lobby = -1
		fetch._impl.start_lobby = -1
	
	
	
	# Apply filter options
	var lobbies: Array = []
	for lobby in g._impl.lobbies:
		if _match_lobby(lobby, fetch):
			lobbies.push_back(lobby)
	
	
	# Apply sort options
	lobbies = _sort_lobbies(lobbies, fetch)
	count = min(20, count)
	var index: int = 0
	if type == "first":
		index = 0
	elif type == "next":
		index = fetch._impl.last_lobby + 1
	elif type == "current":
		index = fetch._impl.start_lobby + 1
	elif type == "previous":
		index = max(fetch._impl.start_lobby - count, 0)
	
	# Get 'count' lobbies.
	var result: Array = []
	for i in range(index, min(index + count, lobbies.size())):
		result.push_back(lobbies[i])
		
	# Write down last lobby for subsequent 'fetch_next' calls.
	if not result.empty():
		var start: int = lobbies.find(result.front()) - 1
		fetch._impl.start_lobby = max(start, -1)
		fetch._impl.last_lobby = lobbies.find(result.back())
	elif index > 0:
		fetch._impl.start_lobby = fetch._impl.last_lobby
	
	yield(_get_tree().create_timer(0.25), "timeout") # fake delay
	return result


static func _generate_address(lobby) -> String:
	var last_address: Array = lobby._impl.last_address
	for i in range(last_address.size() - 1, -1, -1):
		last_address[i] += 1
		if last_address[i] < 256:
			break
		last_address[i] = 0
	
	var address: String = str(last_address[0])
	for i in range(1, last_address.size()):
		address += "." + str(last_address[i])
	
	return address

# Common initialization.
static func _add_lobby(lobby):
	var g = _get_gotm()
	
	lobby.id = _generate_id()
	lobby.invite_link = "https://gotm.io/my-studio/my-game/"
	lobby.invite_link += "?connectToken=" + _generate_id()
	
	lobby._impl = {
		# Not exposed to user, so doesn't have to be a real timestamp.
		"created": g._impl.last_lobby_created,
		"props": {},
		"sortable_props": [],
		"filterable_props": [],
		"last_address": [192, 168, 0, 0]
	}
	g._impl.last_lobby_created += 1
	
	g._impl.lobbies.push_back(lobby)
	return lobby


static func _host_lobby(lobby):
	var g = _get_gotm()
	_leave_lobby(g.lobby)
	
	lobby = _add_lobby(lobby)
	lobby.host = _generate_address(lobby)
	lobby.my_address = lobby.host
	g.lobby = lobby
	g.emit_signal("lobby_changed")
	return lobby


static func _join_lobby(lobby) -> bool:
	var g = _get_gotm()
	_leave_lobby(g.lobby)
	yield(_get_tree().create_timer(0.25), "timeout") # fake delay
	
	if not g._impl.lobbies.has(lobby) or lobby.locked:
		return false
	
	lobby.my_address = _generate_address(lobby)
	g.lobby = lobby
	g.emit_signal("lobby_changed")
	return true


static func _kick_lobby_peer(lobby, peer: String) -> bool:
	var g = _get_gotm()
	
	if lobby.host != lobby.my_address:
		return false
	
	if lobby.my_address == peer:
		_leave_lobby(lobby)
	else:
		lobby.peers.erase(peer)
		if lobby == g.lobby:
			lobby.emit_signal("peer_left", peer)
	
	return true


static func _leave_lobby(lobby) -> void:
	if not lobby:
		return
	
	var g = _get_gotm()
	if g.lobby == lobby:
		if lobby.host == lobby.my_address:
			g._impl.lobbies.erase(lobby)
		lobby.my_address = ""
		g.lobby = null
		g.emit_signal("lobby_changed")


static func _truncate_string(s: String) -> String:
	return s.substr(0, 64)

static func _set_lobby_property(lobby, name: String, value) -> void:
	name = _truncate_string(name)
	if value == null:
		lobby._impl.props.erase(name)
		
	match typeof(value):
		TYPE_BOOL:
			pass
		TYPE_INT:
			pass
		TYPE_REAL:
			pass
		TYPE_STRING:
			value = _truncate_string(value)
		_:
			push_error("Invalid lobby property type.")
			return
			
	lobby._impl.props[name] = value


static func _get_lobby_property(lobby, name: String):
	return lobby._impl.props[_truncate_string(name)]

static func _set_lobby_filterable(lobby, property_name: String, filterable: bool) -> void:
	property_name = _truncate_string(property_name)
	if not filterable:
		lobby._impl.filterable_props.erase(property_name)
	elif not lobby._impl.filterable_props.has(property_name):
		lobby._impl.filterable_props.push_back(property_name)


static func _set_lobby_sortable(lobby, property_name: String, sortable: bool) -> void:
	property_name = _truncate_string(property_name)
	if not sortable:
		lobby._impl.sortable_props.erase(property_name)
	elif not lobby._impl.sortable_props.has(property_name):
		lobby._impl.sortable_props.push_back(property_name)
