class_name GotmPeriod
#warnings-disable


## A utility class for representing a time period.

## A certain time unit.
class TimeGranularity:
## A year starts on the first day of the year and ends on the last day of the year.
## A sliding year starts 365 ago and ends now.
	const YEAR: String = "year"
## A month starts on the first day of the month and ends on the last day of the month.
## A sliding month starts 30 days ago and ends now.
	const MONTH: String = "month"
## A week starts on the week's Monday and ends on the week's Sunday.
## A sliding week starts 7 days ago and ends now.
	const WEEK: String = "week"
## A day starts on the first millisecond of the day and ends at the last millisecond of the day.
## A sliding day starts 24 hours ago and ends now.
	const DAY: String = "day"
## Starts at the absolute beginning of time and ends at the absolut ending of time.
	const ALL: String = ""

## Current time unit.
var granularity: String = TimeGranularity.ALL
## Current year.
var year: int = -1
## Current month, ranging from 0 for January to 11 for December.
var month: int = -1
## Current day, ranging from 0 to 30.
var day: int = -1

## Get a period starting at the absolute beginning of time and ending at the absolute ending of time.
static func all() -> GotmPeriod:
	return _GotmPeriod.all()

## Get a period ending now, but starting one time unit ago.
## For example, if granularity is GotmPeriod.TimeGranularity.YEAR,
## the period will start one year ago and end now.
## The start and end of the period is not static, which means that
## it always ends now, even if the GotmPeriod instance was created 
## several hours ago.
static func sliding(granularity: String) -> GotmPeriod:
	return _GotmPeriod.sliding(granularity)

## Get a period starting and ending within a certain time unit relative to now.
## For example, if granularity is GotmPeriod.TimeGranularity.DAY
## the period will start at 00:00 and end at 23:59 in <offset> days from today.
## So, if offset is 1, the period will start at 00:00 tomorrow and end at 23:59 tomorrow.
## If offset is -1, the period will start at 00:00 yesterday and end at 23:59 yesterday.
static func offset(granularity: String, offset: int = 0) -> GotmPeriod:
	return _GotmPeriod.offset(granularity, offset)

## Get a period starting and ending within a certain time unit.
## For example, if granularity is GotmPeriod.TimeGranularity.MONTH,
## year is 2019 and month is 1, the period will start on the first day of February at 00:00
## and end at the last day of February at 23:59.
static func at(granularity: String, year: int = -1, month: int = -1, day: int = -1) -> GotmPeriod:
	return _GotmPeriod.at(granularity, year, month, day)

## Get a period starting and ending within a current time unit.
## For example, if granularity is GotmPeriod.TimeGranularity.WEEK,
## the period will start on Monday of the current week at 00:00
## and end on Sunday of the current week at 23:59.
static func now(granularity: String) -> GotmPeriod:
	return _GotmPeriod.now(granularity)

## Make a deep copy of a GotmPeriod instance.
func duplicate() -> GotmPeriod:
	return _GotmPeriod.duplicate(self)

## Increment or decrement a period by a certain time unit.
## For example, if the current period is today, granularity is
## GotmPeriod.TimeGranularity.DAY and offset is 1, the
## period will be incremented by one day and becomes tomorrow.
func move(granularity: String, offset: int = 0) -> GotmPeriod:
	return _GotmPeriod.move(self, granularity, offset)

## Get the UNIX epoch time (in milliseconds) for when the period starts. 
## Use OS.get_datetime_from_unix_time(period.to_unix_time() / 1000) to convert to date.
func to_unix_time() -> int:
	return _GotmPeriod.to_unix_time(self)

## Get datetime for the period's start time.
func get_start_datetime(utc: bool = false) -> Dictionary:
	return _GotmPeriod.get_start_datetime(self, utc)

## Get datetime for the period's end time.
func get_end_datetime(utc: bool = false) -> Dictionary:
	return _GotmPeriod.get_end_datetime(self, utc)

## Get a string representation of the period.
func to_string() -> String:
	return _GotmPeriod.period_to_string(self)
