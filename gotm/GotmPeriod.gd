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

class_name GotmPeriod
#warnings-disable


# A utility class for representing a time period.


class TimeGranularity:
	const YEAR = "year"
	const MONTH = "month"
	const WEEK = "week"
	const DAY = "day"
	const ALL = ""

var granularity: String = TimeGranularity.ALL
var year: int = -1
var month: int = -1
var day: int = -1

const MS_PER_DAY := 1000 * 60 * 60 * 24

static func all() -> GotmPeriod:
	return _GotmPeriod.all()

static func sliding(granularity: String) -> GotmPeriod:
	return _GotmPeriod.sliding(granularity)

static func offset(granularity: String, offset: int = 0) -> GotmPeriod:
	return _GotmPeriod.offset(granularity, offset)

static func at(granularity: String, year: int = -1, month: int = -1, day: int = -1) -> GotmPeriod:
	return _GotmPeriod.at(granularity, year, month, day)

static func now(granularity: String) -> GotmPeriod:
	return _GotmPeriod.now(granularity)


func duplicate() -> GotmPeriod:
	return _GotmPeriod.duplicate(self)

func move(granularity: String, offset: int = 0) -> GotmPeriod:
	return _GotmPeriod.move(self, granularity, offset)

func to_unix_time() -> int:
	return _GotmPeriod.to_unix_time(self)

func get_start_datetime(utc: bool = false) -> Dictionary:
	return _GotmPeriod.get_start_datetime(self, utc)

func get_end_datetime(utc: bool = false) -> Dictionary:
	return _GotmPeriod.get_end_datetime(self, utc)

func to_string() -> String:
	return _GotmPeriod.period_to_string(self)
