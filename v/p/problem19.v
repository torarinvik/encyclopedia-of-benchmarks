module problem19

fn is_leap_year(year i64) bool {
	return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

@[export: 'problem19']
pub fn problem19(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut weekday := i64(2) // 1 January 1901 was Tuesday; Sunday is 0.
	mut count := i64(0)
	for year := i64(1901); year <= 2000; year++ {
		for month := i64(1); month <= 12; month++ {
			if weekday == 0 { count++ }
			mut days := i64(31)
			if month == 4 || month == 6 || month == 9 || month == 11 { days = 30 }
			if month == 2 { days = if is_leap_year(year) { 29 } else { 28 } }
			weekday = (weekday + days) % 7
		}
	}
	return count
}
