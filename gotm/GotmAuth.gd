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

class_name GotmAuth
#warnings-disable

# A GotmAuth gives permission to do things on behalf of a user.
#
# A global GotmAuth instance is always active and is used by this
# plugin behind the scenes. You can retrieve the global GotmAuth
# instance by calling yield(GotmAuth.fetch(), "completed").
#
# If the user has signed in, the global GotmAuth instance represents
# that user. If the user has not signed in, the global GotmAuth
# instance represents an unregistered anonymous user (a guest).

##############################################################
# PROPERTIES
##############################################################

# Unique identifier of the user whom the authentication represents.
var user_id: String

# Is true if the user has a registered account.
# Some functions in this plugin requires that the current user
# is registered, for example GotmContent.upvote.
var is_registered: bool

##############################################################
# METHODS
##############################################################

# Get the currently active authentication.
# If the user is not signed in, the returned GotmAuth
# will represent an unregistered anonymous user (a guest).
static func fetch() -> GotmAuth:
	return yield(_GotmAuth.fetch(), "completed")

