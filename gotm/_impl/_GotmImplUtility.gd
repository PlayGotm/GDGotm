# MIT License
#
# Copyright (c) 2020-2020 Macaroni Studios AB
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

class_name _GotmImplUtility
#warnings-disable


static func _fuzzy_compare(a, b, compare_less: bool) -> bool:
	if typeof(a) == typeof(b):
		return a < b if compare_less else a > b
		
		# GDScript doesn't handle comparison of different types very well.
		# Abuse Array's min and max functions instead.
		var m = [a, b].min() if compare_less else [a, b].max()
		if m != null or a == null or b == null:
			return m == a
			  
	# Array method failed. Go with strings instead.
	a = String(a)
	b = String(b)
	return a < b if compare_less else a > b


static func is_less(a, b) -> bool:
	return _fuzzy_compare(a, b, true)


static func is_greater(a, b) -> bool:
	return _fuzzy_compare(a, b, false)