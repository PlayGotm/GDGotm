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
	return _Gotm.create_instance("GotmPeriod")

static func sliding(granularity: String) -> GotmPeriod:
	var period = _Gotm.create_instance("GotmPeriod")
	period.granularity = granularity
	return period

static func offset(granularity: String, offset: int = 0) -> GotmPeriod:
	return now(granularity).move(granularity, offset)

static func at(granularity: String, year: int = -1, month: int = -1, day: int = -1) -> GotmPeriod:
	var period = _Gotm.create_instance("GotmPeriod")
	period.granularity = granularity
	var date = OS.get_date(true)
	period.year = year
	period.month = month
	period.day = day
	if year == -1:
		period.year = date.year
	
	if month == -1:
		period.month = date.month
	else:
		period.month = 1
		period.move(TimeGranularity.MONTH, month - 1)
	
	if day == -1:
		period.day = date.day
	else:
		period.day = 1
		period.move(TimeGranularity.DAY, day - 1)
	return period

static func now(granularity: String) -> GotmPeriod:
	return at(granularity)


func duplicate() -> GotmPeriod:
	var copy = _Gotm.create_instance("GotmPeriod")
	copy.granularity = granularity
	copy.year = year
	copy.month = month
	copy.day = day
	return copy

func move(granularity: String, offset: int = 0) -> GotmPeriod:
	match granularity:
		TimeGranularity.YEAR:
			year += offset
			return self
			
		TimeGranularity.MONTH:
			month += offset
			while month > 12:
				month -= 12
				year += 1
			while month < 1:
				month += 12
				year -= 1
			return self
			
		TimeGranularity.DAY:
			var unix_time: int = to_unix_time()
			unix_time += MS_PER_DAY * offset
			var date = OS.get_datetime_from_unix_time(unix_time / 1000)
			year = date.year
			month = date.month
			day = date.day
			return self
			
		TimeGranularity.WEEK:
			var unix_time: int = to_unix_time()
			unix_time += MS_PER_DAY * 7 * offset
			var date = OS.get_datetime_from_unix_time(unix_time / 1000)
			year = date.year
			month = date.month
			day = date.day
			return self
	
	return self

func to_unix_time() -> int:
	if to_string() == granularity:
		return offset(granularity, -1).to_unix_time()
	return OS.get_unix_time_from_datetime({
		"year": year, 
		"month": month, 
		"day": day, 
		"hour": 0, 
		"minute": 0, 
		"second": 0
	}) * 1000

func get_start_datetime(utc: bool = false) -> Dictionary:
	var unix = to_unix_time()
	if !utc:
		unix += _GotmUtility.get_unix_offset()
	return OS.get_datetime_from_unix_time(unix / 1000)

func get_end_datetime(utc: bool = false) -> Dictionary:
	var unix = duplicate().move(granularity, 1).to_unix_time()
	if !utc:
		unix += _GotmUtility.get_unix_offset()
	return OS.get_datetime_from_unix_time((unix / 1000) - 1)

func to_string() -> String:
	match self.granularity:
		TimeGranularity.YEAR:
			if !(year >= 1):
				return TimeGranularity.YEAR
			return "%04d" % [year]
	
		TimeGranularity.MONTH:
			if !(year >= 1) || !(month >= 1):
				return TimeGranularity.MONTH
			return "%04d-%02d" % [year, month]
	
		TimeGranularity.DAY:
			if  !(year >= 1) || !(month >= 1) || !(day >= 1):
				return TimeGranularity.DAY
			return "%04d-%02d-%02d" % [year, month, day]
	
		TimeGranularity.WEEK:
			if  !(year >= 1) || !(month >= 1) || !(day >= 1):
				return TimeGranularity.WEEK
			return "week%d" % [to_unix_time() / (MS_PER_DAY * 7)]
	
	return ""
