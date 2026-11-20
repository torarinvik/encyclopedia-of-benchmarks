const max_dimension = 8
const max_input_length = 65
const invalid_result = i64(-9223372036854775807) - 1

fn bit_count(value int) int {
	mut remaining := value
	mut count := 0
	for remaining != 0 {
		count += remaining & 1
		remaining >>= 1
	}
	return count
}

@[export: 'ryser_permanent']
pub fn ryser_permanent(input &i64, length usize) i64 {
	if length < 1 || length > max_input_length { return invalid_result }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_dimension { return invalid_result }
		n := int(input[0])
		if length != usize(1+n*n) { return invalid_result }
		mut matrix := [max_dimension*max_dimension]i64{}
		for index in 0 .. n*n {
			value := input[1+index]
			if value < -4 || value > 4 { return invalid_result }
			matrix[index] = value
		}

		mut row_sums := [max_dimension]i64{}
		mut total := i64(0)
		mut previous_gray := 0
		for ordinal in 0 .. (1 << n) {
			gray := ordinal ^ (ordinal >> 1)
			if ordinal != 0 {
				changed := gray ^ previous_gray
				mut column := 0
				for ((changed >> column) & 1) == 0 { column++ }
				direction := if (gray & changed) != 0 { i64(1) } else { i64(-1) }
				for row in 0 .. n {
					row_sums[row] += direction * matrix[row*n+column]
				}
			}
			mut product := i64(1)
			for row in 0 .. n { product *= row_sums[row] }
			if ((n+bit_count(gray)) & 1) != 0 { product = -product }
			total += product
			previous_gray = gray
		}
		return total
	}
}
