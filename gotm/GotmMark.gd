class_name GotmMark


## A GotmMark is an action that a user assigns to something,
## for example an upvote on a GotmContent.
##
## Only registered users (see [method GotmAuth.is_registered]) can create non-local
## marks with [method GotmMark.create]. If an unregistered user creates a mark
## with [method GotmMark.create], the mark will be local as if it was created 
## with [method GotmMark.create_local].
##
## # TODO: Redo documentation
## [br][br] [b][u]Creating a GotmMark Upvote/Downvote[/u][/b]
## [br] When creating a GotmMark, you need to provide two things to the [method create] function:
## [br] 1. A valid target or a valid target.id. Valid targets: [GotmContent]
## [br] 2. A valid GotmMark type. Valid types: [constant GotmMark.UPVOTE] and [constant GotmMark.DOWNVOTE]
## [codeblock]
## var awesome_car := get_node("my_car")
## var content := await GotmContent.create(awesome_car)
## var upvote_mark := await GotmMark.create(content, GotmMark.UPVOTE) # user upvoted content
## [/codeblock]
## [br] If you want to create local device marks, use [method create_local] instead.
##
## [br][br] [b][u]Deleting and Replacing a GotmMark[/u][/b]
## [br] To delete a GotmMark, you need a valid target or a valid target.id.
## [codeblock]
## var awesome_car := get_node("my_car")
## var content := await GotmContent.create(awesome_car)
## var upvote_mark := await GotmMark.create(content, GotmMark.UPVOTE) # user upvoted content
## await GotmMark.delete(upvote_mark)
## var downvote_mark := await GotmMark.create(content, GotmMark.DOWNVOTE) # user downvoted content
## [/codeblock]
## [br] NOTE: If a user creates a downvote after an upvote on the same target (without deleting),
## the upvote will be deleted.
##
## [br][br] [b][u]Getting All Votes[/u][/b]
## [br] To get the total votes of a GotmMark, you need a valid target or a valid target.id.
## [br] Optionally, you can specify if you want only upvotes or downvotes.
## [codeblock]
## var awesome_car := get_node("my_car")
## var content := await GotmContent.create(awesome_car)
## # Assume time passed and people upvoted 10 times, and downvoted 3 times
## var fetched_content := GotmContent.fetch(content)
## var total_votes := await GotmMark.get_count(fetched_content) # returns 13
## var total_upvotes := await GotmMark.get_count(fetched_content, GotmMark.UPVOTE) # returns 10
## var total_downvotes := await GotmMark.get_count(fetched_content, GotmMark.DOWNVOTE) # returns 3
## [/codeblock]

##############################################################
# PROPERTIES
##############################################################

## The types of marks that is available
enum Types { UPVOTE, DOWNVOTE }

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
## Possible types: upvote, downvote
##
## A user cannot have multiple marks of the same type on the same
## target.
##
## Some types are unique within a group. For example, a user
## cannot have both an upvote and a downvote on the same target.
## If a user creates a downvote after an upvote on the same target, 
## the upvote will be deleted.
## Unique groups:
## * upvote, downvote
var type: String

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
static func create(target_or_id, type: Types) -> GotmMark:
	return await _GotmMark.create(target_or_id, type)

## Create a mark that is only stored locally on the user's device. Local marks are not accessible to any other player or device.
static func create_local(target_or_id, type: Types) -> GotmMark:
	return await _GotmMark.create(target_or_id, type, true)

## Delete an existing mark.
static func delete(mark_or_id) -> bool:
	return await _GotmMark.delete(mark_or_id)

## Get an existing mark.
static func fetch(mark_or_id) -> GotmMark:
	return await _GotmMark.fetch(mark_or_id)

## Get all marks all users have assigned to a target.
static func get_count(target_or_id) -> int:
	return await _GotmMark.get_count(target_or_id)

## Get the number of marks with a type all users have assigned to a target.
static func get_count_with_type(target_or_id, type: Types) -> int:
	return await _GotmMark.get_count_with_type(target_or_id, type)

## Get all marks the current user has created for a particular target.
static func list_by_target(target_or_id) -> Array:
	return await _GotmMark.list_by_target(target_or_id)

## Get the marks with a type the current user has created for a particular target.
static func list_by_target_with_type(target_or_id, type: Types) -> Array:
	return await _GotmMark.list_by_target_with_type(target_or_id, type)


##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "GotmMark"
