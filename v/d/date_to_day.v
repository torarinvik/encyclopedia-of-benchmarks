module date_to_day

// Return the English weekday name for a bounded ASCII d/m/yyyy date.
@[export: 'date_to_day']
pub fn date_to_day(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 9 || length > 11 { return -1 }
	if unsafe { input[length - 1] != 0 } { return -1 }
	date_length := length - 1
	mut cursor := usize(0)
	mut fields := [3]int{}
	for field in 0 .. 3 {
		start := cursor
		mut value := 0
		for cursor < date_length {
			byte := unsafe { input[cursor] }
			if byte < 48 || byte > 57 { break }
			value = value * 10 + int(byte - 48)
			cursor++
		}
		digits := cursor - start
		max_digits := if field == 2 { 4 } else { 2 }
		if digits < 1 || digits > max_digits || (field == 2 && digits != 4) { return -1 }
		fields[field] = value
		if field < 2 {
			if cursor >= date_length || unsafe { input[cursor] != 47 } { return -1 }
			cursor++
		}
	}
	if cursor != date_length { return -1 }
	day, month, year := fields[0], fields[1], fields[2]
	if year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 { return -1 }
	leap := year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
	mut month_days := [12]int{31,28,31,30,31,30,31,31,30,31,30,31}
	if leap { month_days[1] = 29 }
	if day > month_days[month - 1] { return -1 }

	mut adjusted_year := year
	mut adjusted_month := month
	if adjusted_month < 3 { adjusted_year--; adjusted_month += 12 }
	year_of_century := adjusted_year % 100
	century := adjusted_year / 100
	weekday := (day + ((adjusted_month + 1) * 26) / 10 + year_of_century +
		year_of_century / 4 + century / 4 + 5 * century) % 7
	names := ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
	name := names[weekday]
	if output_capacity < name.len || unsafe { output == nil } { return -2 }
	for index in 0 .. name.len { unsafe { output[index] = name[index] } }
	return i64(name.len)
}
