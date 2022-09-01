class_name GotmPeriod
#warnings-disable


## A utility class for representing a time period.


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
