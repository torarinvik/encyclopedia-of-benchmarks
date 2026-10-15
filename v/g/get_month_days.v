module get_month_days

fn is_leap_year(year i64) bool {
	return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

// Return the pinned JavaScript helper's month length.
@[export: 'get_month_days']
pub fn get_month_days(month_number i64, year i64) i64 {
	if year < 0 || year > 9999 { return -1 }
	match month_number {
		1, 3, 5, 7, 8, 10, 12 { return 31 }
		4, 6, 9, 11 { return 30 }
		2 { return if is_leap_year(year) { i64(29) } else { i64(28) } }
		else { return -1 }
	}
}
