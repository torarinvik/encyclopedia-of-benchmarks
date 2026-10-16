package problem19

is_leap_year :: proc "contextless" (year: i64) -> bool {
	return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

@(export)
problem19 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 do return -1
	weekday := i64(2) // 1 January 1901 was Tuesday; Sunday is 0.
	count := i64(0)
	for year := i64(1901); year <= 2000; year += 1 {
		for month := i64(1); month <= 12; month += 1 {
			if weekday == 0 do count += 1
			days := i64(31)
			if month == 4 || month == 6 || month == 9 || month == 11 do days = 30
			if month == 2 {
				if is_leap_year(year) do days = 29 else do days = 28
			}
			weekday = (weekday + days) % 7
		}
	}
	return count
}
