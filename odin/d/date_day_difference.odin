package date_day_difference

import "core:c"

MAX_LENGTH :: 21
INVALID_ORDINAL :: i64(-1000000000)

floor_div :: proc(value, divisor: i64) -> i64 {
	quotient := value / divisor
	if value % divisor != 0 && value < 0 do quotient -= 1
	return quotient
}

leap_year :: proc(year: i64) -> bool {
	return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

month_length :: proc(month, year: i64) -> i64 {
	if month == 2 {
		if leap_year(year) do return 29
		return 28
	}
	if month == 4 || month == 6 || month == 9 || month == 11 do return 30
	return 31
}

date_ordinal :: proc(day, month, year: i64) -> i64 {
	prior := year - 1
	adjustment := i64(0)
	if month > 2 {
		if leap_year(year) { adjustment = -1 } else { adjustment = -2 }
	}
	return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) + day + floor_div(367 * month - 362, 12) + adjustment
}

parse_date :: proc(values: [^]i64, start, end: int) -> i64 {
	pos := start
	day, month, year: i64 = 0, 0, 0
	digits := 0
	for pos < end && values[pos] >= 48 && values[pos] <= 57 && digits < 3 {
		day = day * 10 + values[pos] - 48
		digits += 1
		pos += 1
	}
	if digits < 1 || digits > 2 || pos >= end || values[pos] != 47 do return INVALID_ORDINAL
	pos += 1
	digits = 0
	for pos < end && values[pos] >= 48 && values[pos] <= 57 && digits < 3 {
		month = month * 10 + values[pos] - 48
		digits += 1
		pos += 1
	}
	if digits < 1 || digits > 2 || pos >= end || values[pos] != 47 do return INVALID_ORDINAL
	pos += 1
	if end - pos != 4 do return INVALID_ORDINAL
	for pos < end {
		if values[pos] < 48 || values[pos] > 57 do return INVALID_ORDINAL
		year = year * 10 + values[pos] - 48
		pos += 1
	}
	if month < 1 || month > 12 || day < 1 || day > month_length(month, year) do return INVALID_ORDINAL
	return date_ordinal(day, month, year)
}

// Return the absolute day difference; malformed packed dates return -1.
@(export)
date_day_difference :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 17 || length > c.size_t(MAX_LENGTH) do return -1
	separator := int(length)
	for index := 0; index < int(length); index += 1 {
		if values[index] == 124 {
			if separator != int(length) do return -1
			separator = index
		}
	}
	if separator == int(length) do return -1
	first := parse_date(values, 0, separator)
	second := parse_date(values, separator + 1, int(length))
	if first == INVALID_ORDINAL || second == INVALID_ORDINAL do return -1
	if first > second do return first - second
	return second - first
}
