class_name DateUtils

# Date and time utilities
# Note: due to limitations of GDScript (static functions cannot reference the
# original script), this must be instantiated to be used.

# OS.get_time() returns: {
#   'hour': int, 'minute': int, 'second': int
# }
# OS.get_date() returns: {
#   'day': int, 'dst': boolean, 'month': int, 'weekday': int, 'year': int
# }

# Conforms to many of the Standard C (1989 version) datetime string format
# parameters.
# The name translations (weekday name, month name) must be provided, or the
# en_US version will be returned.

# Date calculations are based upon Gregorian Calendar.



# Simple String utilities

static func format(format, value_dict, escape='%'):
	var ret = ""
	var first = true
	var prev_was_escape = false
	for part in format.split(escape, true):
		if first:
			# first string; may be empty
			ret += part
			first = false
		elif part.length() <= 0:
			if ! prev_was_escape:
				ret += escape
			# A "x%%%y" is split into x,,,y
			prev_was_escape = ! prev_was_escape
		else:
			prev_was_escape = false
			var ch = part.left(1)
			if ch in value_dict:
				ret += str(value_dict[ch])
				part = part.right(1)
			ret += part
	return ret
			

static func pad_number(number, min_length = 2, val='0'):
	var ret = str(abs(number))
	while ret.length() < min_length:
		ret = val + ret
	if number < 0:
		ret = '-' + ret
	return ret




static func date_to_str(format, date_obj=null):
	if date_obj == null:
		date_obj = OS.get_date()
	return format(format, date_values({}, date_obj))


static func time_to_str(format, time_obj=null):
	if time_obj == null:
		time_obj = OS.get_time()
	return format(format, time_values({}, time_obj))


static func datetime_to_str(format, date_obj=null, time_obj=null):
	if date_obj == null:
		date_obj = OS.get_date()
	if time_obj == null:
		time_obj = OS.get_time()
	var vals = date_values({}, date_obj)
	vals = time_values(vals, time_obj)
	return format(format, vals)


const _DAYS_IN_MONTH = [-1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# number of days in 400 years
#   y = 401, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_400Y = 146097
# number of days in 100 years
#   y = 101, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_100Y = 36524
# number of days in 4 years
#   y = 5, y*365 + y/4 - y/100 + y/400
const _DAYS_IN_4Y = 1461

const EPOCH = {
	'year': 1970,
	'month': 1,
	'day': 1,
	'hour': 0,
	'minute': 0,
	'second': 0,
}

static func date_add(date_obj, days):
	# Adds the date delta (which is a get_date() structure, but only the
	# Month, day, and year matter).
	return _ord_to_date(_date_to_ord(date_obj) + days)


static func date_a_before_b(date_obj_a, date_obj_b) -> bool:
	var ord_a = _date_to_ord(date_obj_a)
	var ord_b = _date_to_ord(date_obj_b)
	return ord_a < ord_b


static func date_a_before_b_or_equal(date_obj_a, date_obj_b) -> bool:
	var ord_a = _date_to_ord(date_obj_a)
	var ord_b = _date_to_ord(date_obj_b)
	return ord_a <= ord_b


static func extract_date(string_with_date: String) -> Dictionary:
	var date_regex = RegEx.new()
	var compiled = date_regex.compile("(?<year>[0-9]{4,})(?<month>[0-9]{2})(?<day>[0-9]{2})")
	assert(OK == compiled)
	if OK != compiled:
		printerr("Failed to compile date extraction regex")
		return EPOCH
	
	var matches = date_regex.search(string_with_date)
	
	if matches:
		return {
			'year': int(matches.strings[matches.names['year']]),
			'month': int(matches.strings[matches.names['month']]),
			'day': int(matches.strings[matches.names['day']]),
		}
	
	return EPOCH


static func _is_leapyear(year):
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

static func _date_to_ord(date_obj) -> int:
	# Converts a valid date object to days since Jan 1, year 1 (which is day 0).
	var month = int(date_obj["month"])
	var year = int(date_obj["year"])
	var day = int(date_obj["day"])
	assert(month >= 1 && month <= 12)

	var days_in_month
	if month == 2 and _is_leapyear(year):
		days_in_month = 29
	else:
		days_in_month = _DAYS_IN_MONTH[date_obj["month"]]
	assert(day >= 1 && day <= days_in_month)

	# Day 0 == Jan 1, so subtract a day
	day -= 1

	# Days before year:
	var y = year - 1
	day += y*365 + y/4 - y/100 + y/400

	# Days before month, for this year
	for i in range(1, month):
		if i == 2 and _is_leapyear(year):
			day += 29
		else:
			day += _DAYS_IN_MONTH[i]

	return day


static func _ord_to_date(ordinal):
	# Converts days since Jan 1, year 1, to a date object.
	# Note that day 0 is a Sunday.  We're not caring about the
	# Julian / Gegorian calendar changes.

	var ret = {
		"year": 0,
		"day": 0,
		"month": 0,
		"dst": false,
		# + 1 here because that's just how the calendar lines up once we're
		# in the modern era.
		"weekday": (ordinal + 1) % 7
	}

	var n400 = ordinal / _DAYS_IN_400Y
	var n = ordinal % _DAYS_IN_400Y
	var year = n400 * 400 + 1

	var n100 = n / _DAYS_IN_100Y
	n = n % _DAYS_IN_100Y

	var n4 = n / _DAYS_IN_4Y
	n = n % _DAYS_IN_4Y

	var n1 = n / 365
	n = n % 365

	year += n100 * 100 + n4 * 4 + n1
	if n1 == 4 or n100 == 4:
		assert(n != 0)
		ret["year"] = year - 1
		ret["month"] = 12
		ret["day"] = 31
		return ret
	ret["year"] = year

	var is_leapyear = _is_leapyear(year)
	var month = 1
	# n is base 0, so do >= comparison
	while n >= _DAYS_IN_MONTH[month]:
		n -= _DAYS_IN_MONTH[month]
		month += 1
		assert(month <= 12)
	ret["day"] = n + 1
	ret["month"] = month
	return ret


####################################################################################################


static func date_values(ret, date):
	ret['y'] = pad_number(int(date.year) % 100)
	ret['Y'] = str(int(date.year))
	ret['d'] = pad_number(int(date.day))
	ret['D'] = str(int(date.day))
	ret['m'] = pad_number(int(date.month))
	ret['w'] = str(int(date.weekday))
	ret['a'] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][int(date.weekday)]
	ret['A'] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][int(date.weekday)]
	ret['b'] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][int(date.month) - 1]
	ret['B'] = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][int(date.month) - 1]
	return ret

static func time_values(ret, time):
	var ampm
	var hour = int(time.hour)
	var hour12
	if hour == 0:
		ampm = 'AM'
		hour12 = 12
	elif hour < 12:
		ampm = 'AM'
		hour12 = hour
	elif hour == 12:
		ampm = 'PM'
		hour12 = 12
	else:
		ampm = 'PM'
		hour12 = hour - 12

	ret['I'] = pad_number(hour12)
	ret['H'] = pad_number(hour)
	ret['M'] = pad_number(int(time.minute))
	ret['S'] = pad_number(int(time.second))
	ret['p'] = ampm
	return ret

