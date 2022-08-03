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

class_name GotmQuery
#warnings-disable

# A GotmQuery is used for complex filtering and sorting when fetching 
# Gotm resources, such as GotmContent.

# The current state of filters for this query. Is an array of Filter objects.
var filters: Array = []
# The current state of sorts for this query. Is an array of Sort objects.
var sorts: Array = []

# Fetch only things where the property_path's property equals the specified value.
func filter(property_path: String, value) -> GotmQuery:
	return _GotmQuery.filter(self, property_path, value)
	
# Fetch only things where the property_path's property is greater than or equal to
# the specified value.
# If is_exclusive is true, fetch only things where the property_path's property is 
# greater than the specified value.
func filter_min(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return _GotmQuery.filter_min(self, property_path, value, is_exclusive)

# Fetch only things where the property_path's property is less than or equal to
# the specified value.
# If is_exclusive is true, fetch only things where the property_path's property is 
# less than the specified value.
func filter_max(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return _GotmQuery.filter_max(self, property_path, value, is_exclusive)

# Sort results by the value of the property_path's property in descending order (highest value first).
# If ascending is true, sort in ascending order (lowest value first).
func sort(property_path: String, ascending: bool = false) -> GotmQuery:
	return _GotmQuery.sort(self, property_path, ascending)

# Make a deep copy of this GotmQuery instance.
func copy() -> GotmQuery:
	return _GotmQuery.copy(self)

# Create a query directly from filters and sorts.
# Filters is an array of Filter objects.
# Sorts is an array of Sort objects.
#
# For example, doing GotmQuery.create([{"property_path": "name", value: "my_name"}, [{"property_path": "created"}])
# would fetch only things whose name equals "my_name" sorted by creation date in descending order (newest first).
# It is the same as doing GotmQuery.new().filter("name", "my_name").sort("created").
static func create(filters: Array = [], sorts: Array = []) -> GotmQuery:
	return _GotmQuery.create(filters, sorts)

# Represents a filter created by a call to GotmQuery.filter, GotmQuery.filter_min or GotmQuery.filter_max.
class Filter:
	var property_path: String
	var value = null
	var min_value = null
	var max_value = null
	var is_min_exclusive: bool = false
	var is_max_exclusive: bool = false

# Represents a sort created by a call to GotmQuery.sort.
class Sort:
	var property_path: String
	var ascending: bool = false
