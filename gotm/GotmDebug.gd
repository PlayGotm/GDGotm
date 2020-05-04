class_name GotmDebug

# Helper library for testing against the gotm.io API locally.
# Contains functions that fake operations and trigger relevant signals.
# These functions are not run when live.


# Emulate user login
static func login() -> void:
	if Gotm.is_live():
		return
		
	logout()
	
	Gotm.user_id = "user-id"
	Gotm.emit_signal("user_changed")


# Emulate user logout
static func logout() -> void:
	if Gotm.is_live():
		return
	
	if !Gotm.has_user():
		return
		
	Gotm.user_id = ""
	Gotm.emit_signal("user_changed")
