module doomsday

fn is_leap_year(year i64) bool {
	return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

fn month_anchor(month i64, leap bool) i64 {
	match month {
		1 { if leap { return 4 } else { return 3 } }
		2 { if leap { return 1 } else { return 7 } }
		3 { return 7 }
		4 { return 4 }
		5 { return 2 }
		6 { return 6 }
		7 { return 4 }
		8 { return 1 }
		9 { return 5 }
		10 { return 3 }
		11 { return 7 }
		12 { return 5 }
		else { return -1 }
	}
}

@[export: 'doomsday']
pub fn doomsday(values &i64, length usize) i64 {
	if length != 3 { return -1 }
	year := unsafe { values[0] }
	month := unsafe { values[1] }
	day := unsafe { values[2] }
	if year < 100 || year > 9999 || month < 1 || month > 12 { return -1 }
	leap := is_leap_year(year)
	mut days_in_month := i64(31)
	if month == 2 {
		days_in_month = if leap { 29 } else { 28 }
	} else if month == 4 || month == 6 || month == 9 || month == 11 {
		days_in_month = 30
	}
	if day < 1 || day > days_in_month { return -1 }

	within_century := year % 100
	century_anchor := (5 * ((year / 100) % 4) + 2) % 7
	doom := (within_century / 12 + within_century % 12
		+ (within_century % 12) / 4 + century_anchor) % 7
	mut weekday := (doom + day - month_anchor(month, leap)) % 7
	if weekday < 0 { weekday += 7 }
	return weekday
}
