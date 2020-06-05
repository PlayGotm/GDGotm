class_name GotmDebug
#warnings-disable

# Helper library for testing against the API locally, as if it would be live.
#
# These functions do not make real API calls. They fake operations and 
# trigger relevant signals as if they happened live.
#
# These functions do nothing when the game is running live on gotm.io.
# Running the game in the web player (gotm.io/web-player) also counts as live.


# Emulate user login.
# Triggers 'user_changed'
static func login() -> void:
	_GotmDebugImpl._login()


# Emulate user logout
# Triggers 'user_changed'
static func logout() -> void:
	_GotmDebugImpl._logout()


# Add a lobby, as if another player created it.
# Note that the lobby is hidden by default and not fetchable with
# 'GotmLobbyFetch'. To make it fetchable, set 'hidden' to false.
# Returns added lobby.
static func add_lobby() -> GotmLobby:
	return _GotmDebugImpl._add_lobby(GotmLobby.new())


# Remove a lobby, as if its host disconnected from it.
# Triggers 'lobby_changed' if you are in that lobby.
static func remove_lobby(lobby: GotmLobby) -> void:
	_GotmDebugImpl._remove_lobby(lobby)


# Remove all lobbies.
static func clear_lobbies() -> void:
	_GotmDebugImpl._clear_lobbies()


# Add a player to a lobby, as if the player joined it.
# Triggers 'player_joined' if you are in that lobby.
# Returns player's peer address.
static func add_lobby_player(lobby: GotmLobby) -> String:
	return _GotmDebugImpl._add_lobby_player(lobby)


# Remove player from a lobby, as if the player left it.
# Triggers 'lobby_player_left' if you are in that lobby.
static func remove_lobby_player(lobby: GotmLobby, peer: String) -> void:
	 _GotmDebugImpl._remove_lobby_player(lobby, peer)
