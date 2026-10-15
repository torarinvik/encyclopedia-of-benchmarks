package get_month_days

is_leap_year :: proc(year: i64) -> bool {
	return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

// Return the pinned JavaScript helper's month length.
@(export)
get_month_days :: proc "c" (month_number, year: i64) -> i64 {
	if year < 0 || year > 9999 do return -1
	switch month_number {
	case 1, 3, 5, 7, 8, 10, 12: return 31
	case 4, 6, 9, 11: return 30
	case 2: return if is_leap_year(year) then 29 else 28
	case: return -1
	}
}
