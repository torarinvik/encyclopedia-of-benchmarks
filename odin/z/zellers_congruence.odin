package zellers_congruence

import "core:c"

is_leap_year :: proc "contextless" (year: i64) -> bool {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

@(export)
zellers_congruence :: proc "c" (date: [^]i64, length: c.size_t) -> i64 {
	if date == nil || length != 3 do return -1
	year, month, day := date[0], date[1], date[2]
	if year < 46 || year > 8499 || month < 1 || month > 12 || day < 1 do return -1
	maximum_day := i64(31)
	if month == 4 || month == 6 || month == 9 || month == 11 do maximum_day = 30
	if month == 2 {
		if is_leap_year(year) { maximum_day = 29 } else { maximum_day = 28 }
	}
	if day > maximum_day do return -1

	if month <= 2 { year -= 1; month += 12 }
	century := year / 100
	year_of_century := year % 100
	month_term := (260 * month - 539) / 100
	total := day + year_of_century + month_term + century / 4 + year_of_century / 4 - 2 * century
	weekday := total % 7
	if weekday < 0 { weekday += 7 }
	return weekday
}
