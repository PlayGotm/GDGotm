class_name GotmMark
#warnings-disable


## BETA FEATURE
##
## A GotmMark is an action that a user assigns to something, for example
## an upvote on a GotmContent.
## Only registered users (see GotmAuth.is_registered) can create non-local
## marks with GotmMark.create. If an unregistered user creates a mark
## with GotmMark.create, the mark will be local as if it was created 
## with GotmMark.create_local.

##############################################################
# PROPERTIES
##############################################################

## Unique immutable identifier.
var id: String

## Unique identifier of the user who owns the mark.
## Is automatically set to the current user's id when creating the mark.
## If the mark is created while the game runs outside gotm.io, this user will 
## always be an unregistered user with no display name.
## If the mark is created while the game is running on Gotm with a signed in
## user, you can get their display name via GotmUser.fetch.
var user_id: String

## Unique identifier of what the mark is attached to, for example
## a GotmContent id.
## Possible target types: GotmContent
var target_id: String

## The mark's type, for example "upvote" or "downvote".
## Possible names: upvote, downvote
##
## A user cannot have multiple marks of the same name on the same
## target.
##
## Some names are unique within a group. For example, a user
## cannot have both an upvote and a downvote on the same target.
## If a user creates a downvote after an upvote on the same target, 
## the upvote will be deleted.
## Unique groups:
## * upvote, downvote
var name: String

## Is true if this mark was created by an unregistered user or created with GotmMark.create_local.
## Local marks are only stored locally on the user's devicem, and are useful for data that does not 
## need to be accessible to other devices, such as bookmarking favorite content.
var is_local: bool

## UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(mark.created / 1000) to convert to date.
var created: int


##############################################################
# METHODS
##############################################################

## Create a mark for the current user.
## See PROPERTIES above for descriptions of the arguments.
## If the target is local or the current user is unregistered (see GotmAuth.is_registered), the mark will be local as if 
## it was created by GotmMark.create_local.
static func create(target_or_id, name: String) -> GotmMark:
	return yield(_GotmMark.create(target_or_id, name), "completed")

## Create a mark that is only stored locally on the user's device. Local marks are not accessible to any other player or device.
static func create_local(target_or_id, name: String) -> GotmMark:
	return yield(_GotmMark.create_local(target_or_id, name, true), "completed")

## Delete an existing mark.
static func delete(mark_or_id) -> void:
	return yield(_GotmMark.delete(mark_or_id), "completed")

## Get an existing mark.
static func fetch(mark_or_id) -> GotmMark:
	return yield(_GotmMark.fetch(mark_or_id), "completed")

## Get all marks the current user has created for a particular target.
## If name is provided, only fetch the mark with that name.
static func list_by_target(target_or_id, name: String = "") -> Array:
	return yield(_GotmMark.list_by_target(target_or_id, name), "completed")

## Get the number of marks all users have assigned to a target.
## If name is provided, only count marks with that name.
static func get_count(target_or_id, name: String = "") -> int:
	return yield(_GotmMark.get_count(target_or_id, name), "completed")
