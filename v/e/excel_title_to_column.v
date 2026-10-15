module excel_title_to_column

@[export: 'excel_title_to_column']
pub fn excel_title_to_column(values &i64, length usize) i64 {
	if length < 2 || length > 13 { return -1 }
	unsafe {
		count := values[0]
		if count < 1 || count > 12 || length != usize(1 + count) { return -1 }
		mut column := i64(0)
		for index in 0 .. int(count) {
			mut letter := values[1 + index]
			if letter >= 97 && letter <= 122 {
				letter -= 32
			}
			if letter < 65 || letter > 90 { return -1 }
			column = column * 26 + letter - 65 + 1
		}
		return column
	}
}
