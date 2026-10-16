module find_month_calendar

const min_year = i64(1899)
const max_year = i64(2100)
const max_output_bytes = 181

fn is_leap_year(year i64) bool {
	return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
}

fn month_length(year i64, month i64) int {
	if month == 2 && is_leap_year(year) { return 29 }
	if month == 2 { return 28 }
	if month == 4 || month == 6 || month == 9 || month == 11 { return 30 }
	return 31
}

fn start_offset(month i64, year i64) int {
	mut difference := i64(0)
	if year >= 1900 {
		mut current_year := i64(1900)
		for current_year < year {
			difference += if is_leap_year(current_year) { 366 } else { 365 }
			current_year++
		}
		mut current_month := i64(1)
		for current_month < month {
			difference += i64(month_length(year, current_month))
			current_month++
		}
		return int(difference % 7)
	}
	mut current_year := year
	for current_year < 1900 {
		difference += if is_leap_year(current_year) { 366 } else { 365 }
		current_year++
	}
	mut current_month := i64(1)
	for current_month < month {
		difference -= i64(month_length(1900, current_month))
		current_month++
	}
	return int((7 - difference % 7) % 7)
}

fn write_byte(mut output &u8, mut position &int, value u8) {
	unsafe { output[position[0]] = value }
	position[0]++
}

fn write_cell(mut output &u8, mut position &int, day int) {
	if day == 0 {
		for _ in 0 .. 4 { write_byte(mut output, mut position, u8(32)) }
	} else if day >= 10 {
		write_byte(mut output, mut position, u8(48 + day / 10))
		write_byte(mut output, mut position, u8(48 + day % 10))
		write_byte(mut output, mut position, u8(32))
		write_byte(mut output, mut position, u8(32))
	} else {
		write_byte(mut output, mut position, u8(48 + day))
		write_byte(mut output, mut position, u8(32))
		write_byte(mut output, mut position, u8(32))
		write_byte(mut output, mut position, u8(32))
	}
}

@[export: 'find_month_calendar']
pub fn find_month_calendar(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length != 2 { return -1 }
		month, year := values[0], values[1]
		if month < 1 || month > 12 || year < 1899 || year > 2100 { return -1 }

		offset := start_offset(month, year)
		total_cells := offset + month_length(year, month)
		required := 27 + total_cells * 4 + (total_cells + 6) / 7
		if required > max_output_bytes { return -1 }
		if output == nil || output_capacity < usize(required) { return -2 }

		header_text := 'M   T   W   Th  F   S   Su\n'
		mut position := 0
		for index in 0 .. 27 { write_byte(mut output, mut position, header_text[index]) }
		mut cursor := 0
		for cursor < total_cells {
			cells := if total_cells - cursor < 7 { total_cells - cursor } else { 7 }
			for column in 0 .. cells {
				cell := cursor + column
				day := if cell < offset { 0 } else { cell - offset + 1 }
				write_cell(mut output, mut position, day)
			}
			write_byte(mut output, mut position, u8(10))
			cursor += cells
		}
		return i64(position)
	}
}
