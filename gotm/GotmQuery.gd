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


var filters: Dictionary = {}
var sorts: Array = []


func filter(property_path: String, value) -> GotmQuery:
	return self
	
func filter_min(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return self

func filter_max(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return self

func sort(property_path: String, ascending: bool = false) -> GotmQuery:
	return self
	
func copy() -> GotmQuery:
	return self

static func create(filters: Dictionary = {}, sorts: Array = []) -> GotmQuery:
	return _Gotm.create_instance("GotmQuery")



class Sort:
	var name: String
	var min_value = null
	var max_value = null
	var is_min_exclusive: bool = false
	var is_max_exclusive: bool = false
	var ascending: bool = false
