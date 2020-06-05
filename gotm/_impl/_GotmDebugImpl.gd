class_name _GotmDebugImpl
#warnings-disable

static func _login() -> void:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return
		
	_logout()
	
	g.user_id = _GotmImpl._generate_id()
	g.emit_signal("user_changed")


static func _logout() -> void:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return
	
	if !g.has_user():
		return
		
	g.user_id = ""
	g.emit_signal("user_changed")


static func _add_lobby(lobby):
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return lobby
		
	lobby = _GotmImpl._add_lobby(lobby)
	var peer: String = _GotmImpl._generate_id()
	lobby.host = peer
	lobby.peers = []
	return lobby
	

static func _remove_lobby(lobby) -> void:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return
		
	_GotmImpl._leave_lobby(lobby)
	g._impl.lobbies.erase(lobby)


static func _clear_lobbies() -> void:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return
	for lobby in g._impl.lobbies:
		_remove_lobby(lobby)


static func _add_lobby_player(lobby) -> String:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return ""
		
	var id: String = _GotmImpl._generate_id()
	lobby.peers.push_back(id)
	if lobby == g.lobby:
		g.emit_signal("lobby_player_joined", id)
	return id


static func _remove_lobby_player(lobby, peer) -> void:
	var g = _GotmImpl._get_gotm()
	if g.is_live():
		return
	
	if not lobby.peers.has(peer):
		return
		
	if peer == lobby.host:
		_remove_lobby(lobby)
	else:
		lobby.peers.erase(peer)
		if lobby == g.lobby:
			g.emit_signal("lobby_player_left", peer)
		
		
