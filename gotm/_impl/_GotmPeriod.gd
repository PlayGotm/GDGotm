class_name _GotmPeriod


const MS_PER_DAY := 1000 * 60 * 60 * 24


static func all() -> GotmPeriod:
	return GotmPeriod.new()


static func at(granularity: String, year: int = -1, month: int = -1, day: int = -1) -> GotmPeriod:
	var period := GotmPeriod.new()
	period.granularity = granularity
	var date := Time.get_date_dict_from_system(true)
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


static func duplicate(period) -> GotmPeriod:
	var copy = GotmPeriod.new()
	copy.granularity = period.granularity
	copy.year = period.year
	copy.month = period.month
	copy.day = period.day
	return copy


static func get_end_datetime(period, utc: bool = false) -> Dictionary:
	var unix = duplicate(period).move(period.granularity, 1).to_unix_time()
	if !utc:
		unix += _GotmUtility.get_unix_offset()
	@warning_ignore("integer_division")
	return Time.get_datetime_dict_from_unix_time((unix / 1000) - 1)


static func get_start_datetime(period, utc: bool = false) -> Dictionary:
	var unix = to_unix_time(period)
	if !utc:
		unix += _GotmUtility.get_unix_offset()
	@warning_ignore("integer_division")
	return Time.get_datetime_dict_from_unix_time(unix / 1000)


static func move(period: GotmPeriod, granularity: String, offset_amount: int = 0) -> GotmPeriod:
	match granularity:
		TimeGranularity.YEAR:
			period.year += offset_amount
			return period

		TimeGranularity.MONTH:
			period.month += offset_amount
			while period.month > 12:
				period.month -= 12
				period.year += 1
			while period.month < 1:
				period.month += 12
				period.year -= 1
			return period

		TimeGranularity.DAY:
			var unix_time: int = to_unix_time(period)
			unix_time += MS_PER_DAY * offset_amount
			@warning_ignore("integer_division")
			var date = Time.get_datetime_dict_from_unix_time(unix_time / 1000)
			period.year = date.year
			period.month = date.month
			period.day = date.day
			return period

		TimeGranularity.WEEK:
			var unix_time: int = to_unix_time(period)
			unix_time += MS_PER_DAY * 7 * offset_amount
			@warning_ignore("integer_division")
			var date = Time.get_datetime_dict_from_unix_time(unix_time / 1000)
			period.year = date.year
			period.month = date.month
			period.day = date.day
			return period

	return period


static func now(granularity: String) -> GotmPeriod:
	return at(granularity)


static func offset(granularity: String, offset_amount: int = 0) -> GotmPeriod:
	return now(granularity).move(granularity, offset_amount)


static func period_to_string(period: GotmPeriod) -> String:
	match period.granularity:
		TimeGranularity.YEAR:
			if !(period.year >= 1):
				return TimeGranularity.YEAR
			return "%04d" % [period.year]

		TimeGranularity.MONTH:
			if !(period.year >= 1) || !(period.month >= 1):
				return TimeGranularity.MONTH
			return "%04d-%02d" % [period.year, period.month]

		TimeGranularity.DAY:
			if  !(period.year >= 1) || !(period.month >= 1) || !(period.day >= 1):
				return TimeGranularity.DAY
			return "%04d-%02d-%02d" % [period.year, period.month, period.day]

		TimeGranularity.WEEK:
			if  !(period.year >= 1) || !(period.month >= 1) || !(period.day >= 1):
				return TimeGranularity.WEEK
			@warning_ignore("integer_division")
			return "week%d" % [to_unix_time(period) / (MS_PER_DAY * 7)]

	return ""


static func sliding(granularity: String) -> GotmPeriod:
	var period := GotmPeriod.new()
	period.granularity = granularity
	return period


static func to_unix_time(period) -> int:
	if period_to_string(period) == period.granularity:
		return offset(period.granularity, -1).to_unix_time()
	return Time.get_unix_time_from_datetime_dict({
		"year": period.year, 
		"month": period.month, 
		"day": period.day, 
		"hour": 0, 
		"minute": 0, 
		"second": 0
	}) * 1000


class TimeGranularity:
	const YEAR := "year"
	const MONTH := "month"
	const WEEK := "week"
	const DAY := "day"
	const ALL := ""
