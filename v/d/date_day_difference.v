module date_day_difference

const max_length = 21
const invalid_ordinal = i64(-1000000000)

fn floor_div(value i64, divisor i64) i64 {
	mut quotient := value / divisor
	if value % divisor != 0 && value < 0 { quotient-- }
	return quotient
}

fn leap_year(year i64) bool {
	return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

fn month_length(month i64, year i64) i64 {
	if month == 2 { return if leap_year(year) { 29 } else { 28 } }
	if month == 4 || month == 6 || month == 9 || month == 11 { return 30 }
	return 31
}

fn date_ordinal(day i64, month i64, year i64) i64 {
	prior := year - 1
	adjustment := if month <= 2 { i64(0) } else if leap_year(year) { i64(-1) } else { i64(-2) }
	return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) + day + floor_div(367 * month - 362, 12) + adjustment
}

fn parse_date(values &i64, start int, end int) i64 {
	mut pos := start
	mut day := i64(0)
	mut month := i64(0)
	mut year := i64(0)
	mut digits := 0
	for pos < end && unsafe { values[pos] } >= 48 && unsafe { values[pos] } <= 57 && digits < 3 {
		day = day * 10 + unsafe { values[pos] } - 48
		digits++
		pos++
	}
	if digits == 0 || digits > 2 || pos >= end || unsafe { values[pos] } != 47 { return invalid_ordinal }
	pos++
	digits = 0
	for pos < end && unsafe { values[pos] } >= 48 && unsafe { values[pos] } <= 57 && digits < 3 {
		month = month * 10 + unsafe { values[pos] } - 48
		digits++
		pos++
	}
	if digits == 0 || digits > 2 || pos >= end || unsafe { values[pos] } != 47 { return invalid_ordinal }
	pos++
	if end - pos != 4 { return invalid_ordinal }
	for pos < end {
		value := unsafe { values[pos] }
		if value < 48 || value > 57 { return invalid_ordinal }
		year = year * 10 + value - 48
		pos++
	}
	if month < 1 || month > 12 || day < 1 || day > month_length(month, year) { return invalid_ordinal }
	return date_ordinal(day, month, year)
}

// Return the absolute day difference; malformed packed dates return -1.
@[export: 'date_day_difference']
pub fn date_day_difference(values &i64, length usize) i64 {
	if length < 17 || length > max_length { return -1 }
	mut separator := int(length)
	for index in 0 .. int(length) {
		if unsafe { values[index] } == 124 {
			if separator != int(length) { return -1 }
			separator = index
		}
	}
	if separator == int(length) { return -1 }
	first := parse_date(values, 0, separator)
	second := parse_date(values, separator + 1, int(length))
	if first == invalid_ordinal || second == invalid_ordinal { return -1 }
	if first > second { return first - second }
	return second - first
}
