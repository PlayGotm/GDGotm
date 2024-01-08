class_name GotmAuthTest
extends Node

var copy_id_to_clipboard := true
var print_console := true


func fetch() -> void:
	var auth := await GotmAuth.fetch()
	if !auth:
		push_error("Could not fetch auth.")
		return

	if copy_id_to_clipboard:
		DisplayServer.clipboard_set(auth.user_id)
	if print_console:
		print("GotmAuth fetched...")
		print(GotmAuthTest.gotm_auth_to_string(auth))


static func gotm_auth_to_string(auth: GotmAuth) -> String:
	var result := "\nGotmUser:\n"
	result += "[user_id] " + auth.user_id + "\n"
	result += "[is_registered] " + str(auth.is_registered) + "\n"
	return result


func _on_copy_id_toggled(button_pressed: bool):
	copy_id_to_clipboard = button_pressed


func _on_console_print_toggled(button_pressed: bool) -> void:
	print_console = button_pressed
