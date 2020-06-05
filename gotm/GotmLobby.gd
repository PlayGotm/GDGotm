class_name GotmLobby
#warnings-disable

# A lobby is a way of connecting players with eachother as if they
# were on the same local network.
#
# Lobbies can be joined either directly through an 'invite_link', or by
# joining lobbies fetched with the 'GotmLobbyFetch' class.

##############################################################
# SIGNALS
##############################################################
# Player joined the lobby.
# This is only emitted if you are in this lobby.
signal peer_joined(address)

# Player left the lobby.
# This is only emitted if you are in this lobby.
signal peer_left(address)



##############################################################
# READ-ONLY PROPERTIES
##############################################################
# Globally unique identifier.
var id: String

# Addresses of other players in the lobby.
var peers: Array = []

# Your address.
var my_address: String

# Address of the host.
var host: String

# Players can join the lobby directly through this link.
var invite_link: String



##############################################################
# WRITABLE PROPERTIES
##############################################################
# Note that only the host can write to these properties.

# Name that is searchable in the 'fetch_lobbies' function.
# Names longer than 64 characters are truncated.
var name: String = ""

# Prevent the lobby from showing up in fetches?
# Players may still join directly through 'invite_link'
var hidden: bool = true

# Prevent new players from joining?
# Also prevents the lobby from showing up in fetches.
var locked: bool = false



##############################################################
# METHODS
##############################################################
# Asynchronously join this lobby after leaving current lobby.
#
# Use 'var success = yield(lobby.join(), "completed")' to wait for the call to complete
# and retrieve the return value.
#
# Sets 'Gotm.lobby' to the joined lobby if successful.
#
# Asyncronously returns true if successful, else false.
func join() -> bool:
	return yield(_GotmImpl._join_lobby(self), "completed")


# Leave this lobby.
func leave() -> void:
	_GotmImpl._leave_lobby(self)


# Am I the host of this lobby?
func is_host() -> bool:
	return my_address == host


# Get a custom property.
func get_property(name: String):
	return _GotmImpl._get_lobby_property(self, name)



################################
# Host-only methods
################################
# Kick player from this lobby.
# Returns true if successful, else false.
func kick(peer: String) -> bool:
	return _GotmImpl._kick_lobby_peer(self, peer)


# Store up to 10 of your own custom properties in the lobby.
# These are visible to other players when fetching lobbies.
# Only properties of types String, int, float or bool are allowed.
# Integers are converted to floats.
# Strings longer than 64 characters are truncated.
# Setting 'value' to null removes the property.
func set_property(name: String, value) -> void:
	_GotmImpl._set_lobby_property(self, name, value)


# Make this lobby filterable by a custom property.
# Filtering is done when fetching lobbies with 'GotmLobbyFetch'.
# Up to 3 properties can be set as filterable at once.
func set_filterable(property_name: String, filterable: bool = true) -> void:
	_GotmImpl._set_lobby_filterable(self, property_name, filterable)


# Make this lobby sortable by a custom property.
# Sorting is done when fetching lobbies with 'GotmLobbyFetch'.
# Up to 3 properties can be set as sortable at once.
func set_sortable(property_name: String, sortable: bool = true) -> void:
	_GotmImpl._set_lobby_sortable(self, property_name, sortable)



################################
# PRIVATE
################################
var _impl: Dictionary = {}
