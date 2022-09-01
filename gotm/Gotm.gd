extends Node
#warnings-disable


## This is the entrypoint to GDGotm.
##
## Add this script as a global autoload. Make sure the global autoload is named 
## "Gotm". It must be named "Gotm" for it to work.
##
## @tutorial: https://gotm.io/docs/gdgotm


##############################################################
# SIGNALS
##############################################################
## You connected or disconnected from a lobby. Access it at 'Gotm.lobby'
signal lobby_changed()

## Files were drag'n'dropped into the screen.
## The 'files' argument is an array of 'GotmFile'.
signal files_dropped(files, screen)



##############################################################
# PROPERTIES
##############################################################
# These are all read only.

## Player information.
var user: GotmUser = GotmUser.new()

## Current lobby you are in. 
## Is null when not in a lobby.
var lobby: GotmLobby = null

##############################################################
# METHODS
##############################################################

## Initialize GDGotm with the provided configuration.
## See GotmConfig for more details.
static func initialize(config = GotmConfig.new()) -> void:
	_Gotm.initialize(config, {"GotmScore": GotmScore, "GotmPeriod": GotmPeriod, "GotmUser": GotmUser, "GotmQuery": GotmQuery, "GotmContent": GotmContent, "GotmAuth": GotmAuth, "GotmMark": GotmMark, "GotmBlob": GotmBlob})

## The API is live when the game runs on gotm.io.
## Running the game in the web player (gotm.io/web-player) also counts as live.
static func is_live() -> bool:
	return _Gotm.is_live()

static func get_config() -> GotmConfig:
	return _GotmUtility.copy(_Gotm.get_config(), GotmConfig.new())

## Create a new lobby and join it.
##
## If 'show_invitation' is true, show an invitation link in a popup.
##
## By default, the lobby is hidden and is only accessible directly through 
## its 'invite_link'.
## Set 'lobby.hidden' to false to make it fetchable with 'GotmLobbyFetch'.
##
## Returns the hosted lobby (also accessible at 'Gotm.lobby').
static func host_lobby(show_invitation: bool = true) -> GotmLobby:
	return _GotmImpl._host_lobby(GotmLobby.new())


## Play an audio snippet with 'message' as a synthesized voice.
## 'language' is in BCP 47 format (e.g. "en-US" for american english).
## If specified language is not available "en-US" is used.
## Return true if playback succeeded.
func text_to_speech(message: String, language: String = "en-US") -> bool:
	return true # pretend it worked


## Asynchronously open up the browser's file picker.
##
## You can only call this in a user interaction input event, such as a click.
##
## If 'types' is specified, limit the file picker to files with matching file
## types (https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#Unique_file_type_specifiers).
## If 'only_one' is true, only allow the user to pick one file.
##
## If a picking-session is already in progress, the result of that picking-session
## will be asynchronously returned.
##
## Asynchronously return an array of 'GotmFile'.
## Use 'yield(pick_files(), "completed")' to retrieve the return value.
func pick_files(types: Array = Array(), only_one: bool = false) -> Array:
	yield(get_tree().create_timer(0.25), "timeout")
	return []



##############################################################
# PRIVATE
##############################################################
func _ready() -> void:
	_GotmImpl._initialize(GotmLobby, GotmUser)
func _process(delta) -> void:
	_GotmImpl._process()
var _impl: Dictionary = {}
