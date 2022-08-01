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

class_name _GotmQuery
#warnings-disable


static func filter(query, property_path: String, value):
	query.filters[property_path] = value
	return query
	
static func filter_min(query, property_path: String, value, is_exclusive: bool = false):
	query.sorts.push({"property_path": property_path, "min_value": value, "is_min_exclusive": is_exclusive})
	return query

static func filter_max(query, property_path: String, value, is_exclusive: bool = false):
	query.sorts.push({"property_path": property_path, "max_value": value, "is_max_exclusive": is_exclusive})
	return query

static func sort(query, property_path: String, ascending: bool = false):
	query.sorts.push({"property_path": property_path, "ascending": ascending})
	return query

static func copy(query):
	return create(query.filters.duplicate(true), query.sorts.duplicate(true))

static func get_clean(query):
	query = copy(query)
	var filters: Dictionary = query.filters
	var sorts: Array = query.sorts
	for key in filters.keys():
		if !key:
			filters.erase(key)
			continue
		var matching_sorts = []
		for sort in sorts:
			if sort.property_path == key:
				matching_sorts.append(sort)
		for sort in matching_sorts:
			sorts.erase(sort)
	
	if !sorts:
		return query
	
	var final_sort = sorts[sorts.size() - 1]
	var merged_sorts
	for sort in sorts:
		if !sort.has("max_value") && !sort.has("min_value"):
			final_sort = sort
	return query


static func create(filters: Dictionary = {}, sorts: Array = []):
	var query = _Gotm.create_instance("GotmQuery")
	query.filters = filters
	query.sorts = sorts
	return query

