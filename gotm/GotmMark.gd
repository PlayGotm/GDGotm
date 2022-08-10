# MIT License
#
# Copyright (c) 2020-2022 Macaroni Studios AB
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

class_name GotmMark
#warnings-disable


# BETA FEATURE
# A GotmMark is an action that a user assigns to something, for example
# an upvote on a GotmContent.
# Unless the mark target is local, only registered users can create marks 
# with GotmMark.create (see GotmAuth.is_registered).
# Unregistered users can only create marks with GotmMark.create_local.

##############################################################
# PROPERTIES
##############################################################

# Unique immutable identifier.
var id: String

# Unique identifier of the user who owns the mark.
# Is automatically set to the current user's id when creating the mark.
# If the mark is created while the game runs outside gotm.io, this user will 
# always be an unregistered user with no display name.
# If the mark is created while the game is running on Gotm with a signed in
# user, you can get their display name via GotmUser.fetch.
var user_id: String

# Unique identifier of what the mark is attached to, for example
# a GotmContent id.
# Possible target types: GotmContent
var target_id: String

# The mark's type, for example "upvote" or "downvote".
# Possible names: upvote, downvote
#
# A user cannot have multiple marks of the same name on the same
# target.
#
# Some names are unique within a group. For example, a user
# cannot have both an upvote and a downvote on the same target.
# If a user creates a downvote after an upvote on the same target, 
# the upvote will be deleted.
# Unique groups:
# * upvote, downvote
var name: String

# Is true if this mark was created with GotmMark.create_local and is only stored locally on the user's device.
# Is useful for data that does not need to be accessible to other devices, such bookmarking favorite content.
var is_local: bool

# UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(mark.created / 1000) to convert to date.
var created: int


##############################################################
# METHODS
##############################################################

# Create a mark for the current user.
# See PROPERTIES above for descriptions of the arguments.
# Unless the target is local, the current user must be registered to create marks (see GotmAuth.is_registered).
static func create(target_or_id, name: String) -> GotmMark:
	return yield(_GotmMark.create(target_or_id, name), "completed")

# Create a mark that is only stored locally on the user's device. Local marks are not accessible to any other player or device.
# Both registered and unregistered user can create local marks.
static func create_local(target_or_id, name: String) -> GotmMark:
	return yield(_GotmMark.create_local(target_or_id, name, true), "completed")

# Delete an existing mark.
static func delete(mark_or_id) -> void:
	return yield(_GotmMark.delete(mark_or_id), "completed")

# Get an existing mark.
static func fetch(mark_or_id) -> GotmMark:
	return yield(_GotmMark.fetch(mark_or_id), "completed")

# Get all marks the current user has created for a particular target.
# If name is provided, only fetch the mark with that name.
static func list_by_target(target_or_id, name: String = "") -> Array:
	return yield(_GotmMark.list_by_target(target_or_id, name), "completed")

# Get the number of marks with a certain name that have been assigned to 
# a target by all users.
static func get_count(target_or_id, name: String) -> int:
	return yield(_GotmMark.get_count(target_or_id, name), "completed")