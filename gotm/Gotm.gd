# MIT License
#
# Copyright (c) 2020-2021 Macaroni Studios AB
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
# You connected or disconnected from a lobby. Access it at 'Gotm.lobby'
signal lobby_changed()

# Files were drag'n'dropped into the screen.
# The 'files' argument is an array of 'GotmFile'.
signal files_dropped(files, screen)



##############################################################
# PROPERTIES
##############################################################
# These are all read only.

# Player information.
var user: GotmUser = GotmUser.new()

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


# Create a new lobby and join it.
#
# If 'show_invitation' is true, show an invitation link in a popup.
#
# By default, the lobby is hidden and is only accessible directly through 
# its 'invite_link'.
# Set 'lobby.hidden' to false to make it fetchable with 'GotmLobbyFetch'.
#
# Returns the hosted lobby (also accessible at 'Gotm.lobby').
static func host_lobby(show_invitation: bool = true) -> GotmLobby:
	return _GotmImpl._host_lobby(GotmLobby.new())


# Play an audio snippet with 'message' as a synthesized voice.
# 'language' is in BCP 47 format (e.g. "en-US" for american english).
# If specified language is not available "en-US" is used.
# Return true if playback succeeded.
func text_to_speech(message: String, language: String = "en-US") -> bool:
	return true # pretend it worked


# Asynchronously open up the browser's file picker.
#
# You can only call this in a user interaction input event, such as a click.
#
# If 'types' is specified, limit the file picker to files with matching file
# types (https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#Unique_file_type_specifiers).
# If 'only_one' is true, only allow the user to pick one file.
#
# If a picking-session is already in progress, the result of that picking-session
# will be asynchronously returned.
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
	_GotmImpl._initialize(GotmLobby, GotmUser)
func _process(delta) -> void:
	_GotmImpl._process()
var _impl: Dictionary = {}
