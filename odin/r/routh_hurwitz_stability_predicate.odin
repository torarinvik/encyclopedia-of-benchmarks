package routh_hurwitz_stability_predicate

import "core:c"

MAX_DEGREE :: i64(4)
MAX_PARSEABLE_LENGTH :: c.size_t(7)

@(export)
routh_hurwitz_stability_predicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_LENGTH do return -1
	degree := input[0]
	if degree < 1 || degree > MAX_DEGREE || length != c.size_t(degree + 2) do return -1

	coefficients: [5]i64 = {}
	for index := i64(0); index <= degree; index += 1 {
		value := input[c.size_t(index + 1)]
		if value < -3 || value > 3 || (index == 0 && value <= 0) do return -1
		coefficients[index] = value
	}

	width := (degree + 2) / 2
	table: [15]i64 = {}
	for column := i64(0); column < width; column += 1 {
		even_index := 2 * column
		odd_index := even_index + 1
		if even_index <= degree do table[column] = coefficients[even_index]
		if odd_index <= degree do table[3 + column] = coefficients[odd_index]
	}

	row_one_zero := true
	for column := i64(0); column < width; column += 1 {
		if table[3 + column] != 0 do row_one_zero = false
	}
	if row_one_zero || table[3] <= 0 do return 0

	for row := i64(2); row <= degree; row += 1 {
		if table[3 * (row - 1)] <= 0 do return 0
		all_zero := true
		for column := i64(0); column < width; column += 1 {
			upper_next := i64(0)
			lower_next := i64(0)
			if column + 1 < width {
				upper_next = table[3 * (row - 2) + column + 1]
				lower_next = table[3 * (row - 1) + column + 1]
			}
			table[3 * row + column] = table[3 * (row - 1)] * upper_next - table[3 * (row - 2)] * lower_next
			if table[3 * row + column] != 0 do all_zero = false
		}
		if all_zero || table[3 * row] <= 0 do return 0
	}
	return 1
}
