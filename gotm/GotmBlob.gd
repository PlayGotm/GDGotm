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

class_name GotmBlob
#warnings-disable

# A GotmBlob is a piece of arbitrary data stored as a PoolByteArray.
# The data can be anything, such as images, scenes or JSON files.

##############################################################
# PROPERTIES
##############################################################

# Unique immutable identifier.
var id: String

# The size of the blob's data in bytes.
var size: int

# Is true if this blob is only stored locally on the user's device.
var is_local: bool

##############################################################
# METHODS
##############################################################

# Get an existing blob.
static func fetch(blob_or_id) -> GotmBlob:
	return yield(_GotmBlob.fetch(blob_or_id), "completed")

# Get the blob's data as a PoolByteArray.
static func fetch_data(blob_or_id) -> PoolByteArray:
	return yield(_GotmBlob.fetch_data(blob_or_id), "completed")
