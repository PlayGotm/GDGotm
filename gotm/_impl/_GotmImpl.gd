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
		
		if fetch.sort_ascending:
			return _GotmImplUtility.is_less(a, b)
		else:
			return _GotmImplUtility.is_greater(a, b)


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


# Initialize socket for fetching lobbies on local network.
static func _init_socket() -> void:
	var g = _get_gotm()
	if !g._impl.sockets:
		g._impl.sockets = []
		var is_listening = false
		for i in range(5):
			var socket = PacketPeerUDP.new()
			if socket.has_method("set_broadcast_enabled"):
				socket.set_broadcast_enabled(true)
			if !is_listening:
				is_listening = socket.listen(8075 + i) == OK
			socket.set_dest_address("255.255.255.255", 8075 + i)
			g._impl.sockets.push_back(socket)
		
		if !is_listening:
			push_error("Failed to listen for lobbies. All ports 8075-8079 are busy.")


# Attach some global state to autoloaded Gotm instance.
static func _initialize(GotmLobbyT, GotmUserT) -> void:
	var g = _get_gotm()
		
	g._impl = {
		"lobbies": [],
		"chars": "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-",
		"rng": RandomNumberGenerator.new(),
		"search_string_encoders": _init_search_string_encoders(),
		"sockets": null,
		"lobby_requests": {},
		"GotmLobbyT": GotmLobbyT,
		"GotmUserT": GotmUserT,
		"is_listening": false
	}
	g._impl.rng.randomize()
	g.user._impl.id = _generate_id()
	g.user.address = "localhost"


static func _process() -> void:
	var g = _get_gotm()
	
	if g.lobby:
		if OS.get_system_time_msecs() - g.lobby._impl.last_heartbeat > 2500:
			_init_socket()
			_put_sockets({
				"op": "peer_heartbeat", 
				"data": {
					"lobby_id": g.lobby.id,
					"id": g.user._impl.id
				}
			})
			g.lobby._impl.last_heartbeat = OS.get_system_time_msecs()
	
	if g._impl.sockets:
		for socket in g._impl.sockets:
			while socket.get_available_packet_count() > 0:
				var v = socket.get_var()
				if v.op == "get_lobbies":
					var data = null
					if g.lobby && g.lobby.is_host() && !g.lobby.hidden && !g.lobby.locked:
						data = {
							"id": g.lobby.id,
							"name": g.lobby.name,
							"peers": [],
							"invite_link": g.lobby.invite_link,
							"_impl": g.lobby._impl
						}
					
					_put_sockets({"op": "lobby", "data": data, "id": v.id})
				elif v.op == "leave_lobby":
					if g.lobby && v.data.lobby_id == g.lobby.id:
						if g.lobby.is_host():
							_put_sockets({
								"op": "peer_left", 
								"data": {
									"lobby_id": g.lobby.id, 
									"id": v.data.id
								}
							})
						elif v.data.id == g.lobby.host._impl.id:
							_leave_lobby(g.lobby)
				elif v.op == "join_lobby":
					var data = null
					if g.lobby && g.lobby.is_host() && v.data.lobby_id == g.lobby.id &&  !g.lobby.locked:
						_put_sockets({
							"op": "peer_joined", 
							"data": {
								"lobby_id": g.lobby.id, 
								"address": socket.get_packet_ip(),
								"id": v.data.id
							},
							"id": v.id
						})
						
						var peers = []
						for peer in g.lobby.peers:
							peers.push_back({"address": peer.address, "_impl": peer._impl})
						data = {
							"id": g.lobby.id,
							"name": g.lobby.name,
							"peers": peers,
							"invite_link": g.lobby.invite_link,
							"_impl": g.lobby._impl
						}
					_put_sockets({"op": "lobby", "data": data, "id": v.id})
				elif v.op == "peer_left":
					if g.lobby && v.data.lobby_id == g.lobby.id:
						for peer in g.lobby.peers.duplicate():
							if peer._impl.id == v.data.id:
								g.lobby.peers.erase(peer)
								g.lobby.emit_signal("peer_left", peer)
				elif v.op == "peer_joined":
					if g.lobby && v.data.lobby_id == g.lobby.id && !g._impl.lobby_requests.has(v.id):
						var peer = g._impl.GotmUserT.new()
						peer.address = v.data.address
						peer._impl.id = v.data.id
						g.lobby.peers.push_back(peer)
						g.lobby.emit_signal("peer_joined", peer)
						if g.lobby.is_host():
							g.lobby._impl.heartbeats[v.data.id] = OS.get_system_time_msecs()
				elif v.op == "peer_heartbeat":
					if g.lobby && v.data.lobby_id == g.lobby.id:
						g.lobby._impl.heartbeats[v.data.id] = OS.get_system_time_msecs()
				elif v.op == "lobby":
					if v.data && g._impl.lobby_requests.has(v.id):
						var lobby = g._impl.GotmLobbyT.new()
						var peers = []
						if !v.data._impl.host_id.empty():
							v.data.peers.push_back({
								"address": socket.get_packet_ip(), 
								"_impl": {
									"id": v.data._impl.host_id
								}
							})
						for peer in v.data.peers:
							var p = g._impl.GotmUserT.new()
							p.address = peer.address
							p._impl = peer._impl
							peers.push_back(p)
							
						lobby.hidden = false
						lobby.locked = false
						lobby.id = v.data.id
						lobby.name = v.data.name
						lobby.peers = peers
						lobby.invite_link = v.data.invite_link
						lobby._impl = v.data._impl
						lobby._impl.address = socket.get_packet_ip()
						lobby.me.address = "127.0.0.1"
						lobby.host.address = socket.get_packet_ip()
						lobby.host._impl.id = v.data._impl.host_id
						g._impl.lobby_requests[v.id].push_back(lobby)
						
			if g.lobby:
				for peer_id in g.lobby._impl.heartbeats.duplicate():
					if OS.get_system_time_msecs() - g.lobby._impl.heartbeats[peer_id] > 10000:
						if g.lobby.is_host():
							_put_sockets({
								"op": "peer_left", 
								"data": {
									"lobby_id": g.lobby.id, 
									"id": peer_id
								}
							})
							g.lobby._impl.heartbeats.erase(peer_id)
						elif peer_id == g.lobby.host._impl.id:
							_leave_lobby(g.lobby)
							break
	



# Improve search experience a little by adding fuzziness.
static func _encode_search_string(s: String) -> String:
	s = s.to_lower()
	var encoders: Array = _get_gotm()._impl.search_string_encoders
	for encoder in encoders:
		s = encoder[0].sub(s, encoder[1], true)
	return s


# Return true if 'lobby' matches filter options in 'fetch'.
static func _match_lobby(lobby, fetch) -> bool:
	if lobby.locked || lobby.hidden:
		return false
	
	if !fetch.filter_name.empty():
		var name: String = _encode_search_string(lobby.name)
		var query: String = _encode_search_string(fetch.filter_name)
		if !query.empty() && name.find(query) < 0:
			return false
	
	var lobby_props: Dictionary = {}
	for key in lobby._impl.filterable_props:
		if !lobby._impl.props.has(key):
			return false
		if !fetch.filter_properties.has(key):
			return false
		
		var lhs = fetch.filter_properties[key]
		var rhs = lobby._impl.props[key]
		if lhs != null && lhs != rhs:
			return false
		
	return true


# Used to detect changes.
static func _stringify_fetch_state(fetch) -> String:
	var d: Array = [
		fetch.filter_name,
		fetch.filter_properties,
		fetch.sort_property,
		fetch.sort_property,
	fetch.sort_ascending,
	fetch.sort_min,
	fetch.sort_max,
	fetch.sort_min_exclusive,
	fetch.sort_max_exclusive
	]
	return JSON.print(d)
	


# Return sorted copy of 'lobbies' using sort options in 'fetch'.
static func _sort_lobbies(lobbies: Array, fetch) -> Array:
	var sorted: Array = []
	var g = _get_gotm()
	for lobby in lobbies:
		if fetch.sort_property.empty():
			sorted.push_back(lobby)
			
		var v = lobby._impl.props.get(fetch.sort_property)
		if v == null:
			continue
		if fetch.sort_min != null:
			if _GotmImplUtility.is_less(v, fetch.sort_min):
				continue
			if fetch.sort_min_exclusive && !_GotmImplUtility.is_greater(v, fetch.sort_min):
				continue
		if fetch.sort_max != null:
			if _GotmImplUtility.is_greater(v, fetch.sort_max):
				continue
			if fetch.sort_max_exclusive && !_GotmImplUtility.is_less(v, fetch.sort_max):
				continue
		
		sorted.push_back(lobby)
		
	
	var sorter: LobbySorter = LobbySorter.new()
	sorter.fetch = fetch
	sorter.g = g
	sorted.sort_custom(sorter, "sort")
	
	return sorted	


static func _put_sockets(v: Dictionary):
	_init_socket()
	for socket in _get_gotm()._impl.sockets:
		socket.put_var(v)


static func _request_lobbies() -> Array:
	var g = _get_gotm()
	var request_id: String = _generate_id()
	g._impl.lobby_requests[request_id] = []
	_put_sockets({"op": "get_lobbies", "id": request_id})
	yield(g.get_tree().create_timer(0.5), "timeout")
	
	var lobbies = g._impl.lobby_requests[request_id]
	g._impl.lobby_requests.erase(request_id)
	return lobbies


static func _request_join(lobby_id: String):
	var g = _get_gotm()
	var request_id: String = _generate_id()
	g._impl.lobby_requests[request_id] = []
	_put_sockets({
		"op": "join_lobby", 
		"id": request_id, 
		"data": {
			"lobby_id": lobby_id,
			"id": g.user._impl.id
		}
	})
	yield(g.get_tree().create_timer(0.5), "timeout")
	
	var lobbies = g._impl.lobby_requests[request_id]
	g._impl.lobby_requests.erase(request_id)
	for lobby in lobbies:
		if lobby:
			return lobby
	return null


static func _fetch_lobbies(fetch, count: int, type: String) -> Array:
	var g = _get_gotm()
	
	# Reset fetch state if user has modified any options.
	var stringified_state: String = _stringify_fetch_state(fetch)
	if !fetch._impl.has("last_state") || stringified_state != fetch._impl.last_state:
		fetch._impl.last_state = stringified_state
		fetch._impl.last_lobby = -1
		fetch._impl.start_lobby = -1
	
	
	# Apply filter options
	var lobbies: Array = []
	for lobby in yield(_request_lobbies(), "completed") + g._impl.lobbies:
		if _match_lobby(lobby, fetch):
			lobbies.push_back(lobby)
	
	# Apply sort options
	lobbies = _sort_lobbies(lobbies, fetch)
	count = min(8, count)
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
		
	# Write down last lobby for subsequent 'next' calls.
	if !result.empty():
		var start: int = lobbies.find(result.front()) - 1
		fetch._impl.start_lobby = max(start, -1)
		fetch._impl.last_lobby = lobbies.find(result.back())
	elif index > 0:
		fetch._impl.start_lobby = fetch._impl.last_lobby
	
	yield(_get_tree().create_timer(0.25), "timeout") # fake delay
	return result


# Common initialization.
static func _add_lobby(lobby):
	var g = _get_gotm()
	
	lobby.id = _generate_id()
	lobby.invite_link = "https://gotm.io/my-studio/my-game/"
	lobby.invite_link += "?connectToken=" + _generate_id()
	lobby._impl = {
		# Not exposed to user, so doesn't have to be a real timestamp.
		"created": OS.get_system_time_msecs(),
		"props": {},
		"sortable_props": [],
		"filterable_props": [],
		"heartbeats": {},
		"last_heartbeat": 0,
		"host_id": "",
		"address": ""
	}
	lobby.me._impl.id = g.user._impl.id
	
	g._impl.lobbies.push_back(lobby)
	return lobby


static func _host_lobby(lobby):
	var g = _get_gotm()
	_leave_lobby(g.lobby)
	
	lobby = _add_lobby(lobby)
	lobby._impl.address = "127.0.0.1"
	lobby.host.address = "127.0.0.1"
	lobby._impl.host_id = g.user._impl.id
	lobby.host._impl.id = g.user._impl.id
	lobby.me.address = "127.0.0.1"
	g.lobby = lobby
	g.emit_signal("lobby_changed")
	
	_init_socket()
		
	return lobby


static func _join_lobby(lobby) -> bool:
	var g = _get_gotm()
	_leave_lobby(g.lobby)
	
	if !g._impl.lobbies.has(lobby):
		lobby = yield(_request_join(lobby.id), "completed")
	else:
		yield(g.get_tree().create_timer(0.25), "timeout")
	
	if !lobby || lobby.locked:
		return false	
	
	lobby.host.address = lobby._impl.address
	lobby.host._impl.id = lobby._impl.host_id
	lobby.me.address = "127.0.0.1"
	g.lobby = lobby
	g.emit_signal("lobby_changed")
	return true


static func _is_lobby_host(lobby) -> bool:
	var g = _get_gotm()
	return lobby.host._impl.id == g.user._impl.id


static func _kick_lobby_peer(lobby, peer) -> bool:
	var g = _get_gotm()
	
	if !lobby.is_host():
		return false
	
	if g.user._impl.id == peer._impl.id:
		_leave_lobby(lobby)
	else:
		for p in lobby.peers.duplicate():
			if p._impl.id != peer._impl.id:
				continue
			lobby.peers.erase(p)
			if lobby == g.lobby:
				lobby.emit_signal("peer_left", p)
			break
	
	return true


static func _leave_lobby(lobby) -> void:
	if !lobby:
		return
	
	var g = _get_gotm()
	if g.lobby == lobby:
		if lobby.host.address == lobby.me.address:
			g._impl.lobbies.erase(lobby)
		lobby.me.address = ""
		lobby.host.address = ""
		_put_sockets({
			"op": "leave_lobby", 
			"data": {
				"lobby_id": lobby.id,
				"id": g.user._impl.id
			}
		})
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
	if !filterable:
		lobby._impl.filterable_props.erase(property_name)
	elif !lobby._impl.filterable_props.has(property_name):
		lobby._impl.filterable_props.push_back(property_name)


static func _set_lobby_sortable(lobby, property_name: String, sortable: bool) -> void:
	property_name = _truncate_string(property_name)
	if !sortable:
		lobby._impl.sortable_props.erase(property_name)
	elif !lobby._impl.sortable_props.has(property_name):
		lobby._impl.sortable_props.push_back(property_name)
