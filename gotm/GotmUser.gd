class_name GotmUser
#warnings-disable

## Holds information about a Gotm user.



##############################################################
# PROPERTIES
##############################################################
## These are all read-only.

## Globally unique ID.
var id: String = ""

## Current nickname. Can be changed at https://gotm.io/settings
var display_name: String = ""

## The IP address of the user.
## Is empty if you are not in the same lobby.
var address: String = ""

##############################################################
# METHODS
##############################################################

## Fetch registered user by id.
## A registered user is someone who has signed up on Gotm.
## Returns null if there is no registered user with that id.
static func fetch(id: String) -> GotmUser:
	return yield(_GotmUser.fetch(id), "completed")

##############################################################
# PRIVATE
##############################################################
var _impl: Dictionary = {}
