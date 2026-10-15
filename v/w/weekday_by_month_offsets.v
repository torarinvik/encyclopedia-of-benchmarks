module weekday_by_month_offsets

fn is_leap_year(year i64) bool {
	return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

fn month_offset(month i64) i64 {
	match month {
		1 { return 0 }
		2 { return 3 }
		3 { return 2 }
		4 { return 5 }
		5 { return 0 }
		6 { return 3 }
		7 { return 5 }
		8 { return 1 }
		9 { return 4 }
		10 { return 6 }
		11 { return 2 }
		12 { return 4 }
		else { return -1 }
	}
}

@[export: 'weekday_by_month_offsets']
pub fn weekday_by_month_offsets(values &i64, length usize) i64 {
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

	adjusted_year := if month < 3 { year - 1 } else { year }
	return (adjusted_year + adjusted_year / 4 - adjusted_year / 100
		+ adjusted_year / 400 + month_offset(month) + day) % 7
}
