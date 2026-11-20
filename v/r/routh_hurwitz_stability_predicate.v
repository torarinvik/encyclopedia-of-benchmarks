module routh_hurwitz_stability_predicate

@[export: 'routh_hurwitz_stability_predicate']
pub fn routh_hurwitz_stability_predicate(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 7 { return -1 }
	unsafe {
		degree := input[0]
		if degree < 1 || degree > 4 || length != usize(degree + 2) { return -1 }
		mut coefficients := [5]i64{}
		for index in 0 .. int(degree + 1) {
			value := input[index + 1]
			if value < -3 || value > 3 || (index == 0 && value <= 0) { return -1 }
			coefficients[index] = value
		}
		width := int((degree + 2) / 2)
		mut table := [15]i64{}
		for column in 0 .. width {
			even_index := 2 * column
			odd_index := even_index + 1
			if even_index <= int(degree) { table[column] = coefficients[even_index] }
			if odd_index <= int(degree) { table[3 + column] = coefficients[odd_index] }
		}
		mut row_one_zero := true
		for column in 0 .. width { if table[3 + column] != 0 { row_one_zero = false } }
		if row_one_zero || table[3] <= 0 { return 0 }
		for row in 2 .. int(degree + 1) {
			if table[3 * (row - 1)] <= 0 { return 0 }
			mut all_zero := true
			for column in 0 .. width {
				mut upper_next := i64(0)
				mut lower_next := i64(0)
				if column + 1 < width {
					upper_next = table[3 * (row - 2) + column + 1]
					lower_next = table[3 * (row - 1) + column + 1]
				}
				table[3 * row + column] = table[3 * (row - 1)] * upper_next - table[3 * (row - 2)] * lower_next
				if table[3 * row + column] != 0 { all_zero = false }
			}
			if all_zero || table[3 * row] <= 0 { return 0 }
		}
		return 1
	}
}
