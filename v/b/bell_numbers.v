module bell_numbers

// Return the exact Bell number for indices that fit in signed 64-bit output.
@[export: 'bell_numbers']
pub fn bell_numbers(n i64) i64 {
	if n < 0 || n > 25 { return -1 }
	if n == 0 { return 1 }

	mut row := [26]i64{}
	row[0] = 1
	for current in 1 .. int(n) {
		previous_first := row[0]
		previous_last := row[current - 1]
		row[0] = previous_last
		mut previous_old := previous_first
		for column in 1 .. current + 1 {
			mut old_value := i64(0)
			if column < current { old_value = row[column] }
			row[column] = row[column - 1] + previous_old
			previous_old = old_value
		}
	}
	return row[int(n) - 1]
}
