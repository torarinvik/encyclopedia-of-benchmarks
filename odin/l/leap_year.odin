package leap_year

// Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
@(export)
leap_year :: proc "c" (year: i64) -> i64 {
	if year <= 0 do return -1
	if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) do return 1
	return 0
}
