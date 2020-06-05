extends Node
#warnings-disable


# Official GDScript API for games on gotm.io
# This plugin serves as a polyfill while developing against the API locally.

# The 'real' API calls are only available when running the game live on gotm.io. 
# Running the game in the web player (gotm.io/web-player) also counts as live.

# Add this script as a global autoload. Make sure the global autoload is named 
# "Gotm". It must be named "Gotm" for it to work.


##############################################################
# SIGNALS
##############################################################
# User has logged in or out. Access it at 'Gotm.user_id'.
signal user_changed()

# You connected or disconnected from a lobby. Access it at 'Gotm.lobby'
signal lobby_changed()

# Files were drag'n'dropped into the screen.
# The 'files' argument is an array of 'GotmFile'.
signal files_dropped(files, screen)



##############################################################
# PROPERTIES
##############################################################
# These are all read only.

# Globally unique user identifier for logged in user.
# Is empty when no user is logged in.
var user_id: String = ""

# Current lobby you are in. 
# Is null when not in a lobby.
var lobby: GotmLobby = null


##############################################################
# METHODS
##############################################################

# The API is live when the game runs on gotm.io.
# Running the game in the web player (gotm.io/web-player) also counts as live.
func is_live() -> bool:
	return false


# Is the user logged in?
func has_user() -> bool:
	return user_id != ""


# Create a new lobby and join it.
#
# By default, the lobby is hidden and is only accessible directly through 
# its 'invite_link'.
# Set 'lobby.hidden' to false to make it fetchable with 'GotmLobbyFetch'.
#
# Returns the hosted lobby (also accessible at 'Gotm.lobby').
static func host_lobby() -> GotmLobby:
	return _GotmImpl._host_lobby(GotmLobby.new())


# Play an audio snippet with 'message' as a synthesized voice.
# 'language' is in BCP 47 format (e.g. "en-US" for american english).
# If specified language is not available "en-US" is used.
# Return true if playback succeeded.
func text_to_speech(message: String, language: String = "en-US") -> bool:
	return true # pretend it worked


# Asynchronously open up the browser's file picker.
#
# If 'types' is specified, limit the file picker to files with matching file
# types (https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#Unique_file_type_specifiers).
# If 'only_one' is true, only allow the user to pick one file.
#
# Calling this function while a picking-session is in progress, an empty
# array is asynchronously returned.
#
# Asynchronously return an array of 'GotmFile'.
# Use 'yield(pick_files(), "completed")' to retrieve the return value.
func pick_files(types: Array = Array(), only_one: bool = false) -> Array:
	yield(get_tree().create_timer(0.25), "timeout")
	return []



##############################################################
# PRIVATE
##############################################################
func _ready() -> void:
	_GotmImpl._initialize()
var _impl: Dictionary = {}
