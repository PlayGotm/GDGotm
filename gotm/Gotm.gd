extends Node

# Official GDScript API for games on gotm.io
# This plugin serves as a polyfill while developing against the API locally.
# The 'real' API calls are only available when running the game live on gotm.io. 
# Add this script as a global autoload. Make sure the global autoload is named "Gotm". 
# It must be named "Gotm" for it to work.

# User has logged in or out.
signal user_changed

# Globally unique user identifier.
# Is empty when no user is logged in.
var user_id: String = ""


# The API is live when the game runs on gotm.io.
# Running the game in the web player (gotm.io/web-player) also counts as live.
static func is_live() -> bool:
	return false


# Is the user logged in?
func has_user() -> bool:
	return user_id != ""


# Play an audio snippet with `message` as a synthesized voice.
# `language` is in BCP 47 format (e.g. "en-US").
# If specified language is not available "en-US" is used.
# Return true if playback succeeded.
func text_to_speech(message: String, language: String) -> bool:
	return true # pretend it worked

