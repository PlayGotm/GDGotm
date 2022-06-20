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

class_name _GotmScoreUtility
#warnings-disable


class BigInt:
	const MAX := 1000000000
	const NUMBER_COUNT = 10
	var parts := [0]
	
	static func from_integer(n: int) -> BigInt:
		var big := BigInt.new()
		big.parts[0] = n
		big.add(BigInt.new())
		return big
	
	func multiply(n: int) -> BigInt:
		var i := 0
		var carry := 0
		while i < parts.size() || carry > 0:
			if i >= parts.size():
				parts.append(0)
			var tmp = 2 * parts[i] + carry
			parts[i] = tmp % MAX
			carry = tmp / MAX
			i += 1
		return self
	
	func shift_left(n: int) -> BigInt:
		for i in range(0, n):
			multiply(2)
		return self
	
	func add(big: BigInt) -> BigInt:
		var i := 0
		var carry := 0
		while i < parts.size() && i < big.parts.size() || carry > 0:
			var value := 0
			if i >= parts.size():
				parts.append(0)
			if i < big.parts.size():
				value = big.parts[i]
			var tmp = value + parts[i] + carry
			parts[i] = tmp % MAX
			carry = tmp / MAX
			i += 1
		return self
	
	func to_string() -> String:
		if parts.empty():
			return "0"
		var i := parts.size() - 1
		var string := String(parts[i])
		i -= 1
		while i >= 0:
			var part = String(parts[i])
			while part.length() < NUMBER_COUNT - 1:
				part = "0" + part
			string += part
			i -= 1
		return string

const NUM_FIXED_WIDTH_DECIMAL_BITS := 52
const INT_2_RAISED_52 = pow(2, 52)


static func _get_fixed_width_float_big_int(value: float) -> BigInt:
	var integer := int(value)
	var big_integer := BigInt.from_integer(integer)
	var float_decimals := value - float(integer)
	var big_decimals := BigInt.from_integer(int(float_decimals * float(INT_2_RAISED_52)))
	return big_integer.shift_left(NUM_FIXED_WIDTH_DECIMAL_BITS).add(big_decimals)

static func encode_cursor_value(value: float, created: int = 0) -> Dictionary:
	var big_value := _get_fixed_width_float_big_int(value)
	var big_created := BigInt.from_integer(created)
	return {"_bigint": big_value.shift_left(64).add(big_created).to_string()}
