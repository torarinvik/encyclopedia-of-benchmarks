module linear_recurrence_matrix


fn multiply_matrix(left []i64, right []i64, dimension int) []i64 {
	mut output := []i64{len: dimension * dimension}
	for row in 0 .. dimension {
		for column in 0 .. dimension {
			mut value := i64(0)
			for inner in 0 .. dimension {
				value = (value + (left[row * dimension + inner] % 1_000_000_007) *
					(right[inner * dimension + column] % 1_000_000_007) % 1_000_000_007) % 1_000_000_007
			}
			output[row * dimension + column] = value
		}
	}
	return output
}

fn matrix_power(matrix []i64, dimension int, initial_power i64) []i64 {
	mut zero := true
	for index in 0 .. dimension * dimension {
		if matrix[index] != 0 { zero = false }
	}
	if zero { return []i64{len: dimension * dimension} }
	mut result := []i64{len: dimension * dimension}
	mut base := matrix.clone()
	for index in 0 .. dimension { result[index * dimension + index] = 1 }
	mut power := initial_power
	for power > 0 {
		if (power & 1) != 0 { result = multiply_matrix(result, base, dimension) }
		power /= 2
		base = multiply_matrix(base, base, dimension)
	}
	return result
}

@[export: 'linear_recurrence_matrix']
pub fn linear_recurrence_matrix(input &i64, length usize) i64 {
	if length < 3 || length > 24 { return -1 }
	dimension_value := unsafe { input[0] }
	nth_term := unsafe { input[1] }
	constant_or_sum_included := unsafe { input[2] }
	if dimension_value < 1 || dimension_value > 4 || nth_term < 0 || nth_term > 1_000_000 ||
		(constant_or_sum_included != 0 && constant_or_sum_included != 1) { return -1 }
	dimension := int(dimension_value)
	matrix_count := dimension * dimension
	if length != usize(3 + matrix_count + dimension) ||
		(constant_or_sum_included == 1 && nth_term < dimension_value - 1) { return -1 }
	mut matrix := []i64{len: matrix_count}
	mut base_row := []i64{len: dimension}
	for index in 0 .. matrix_count + dimension {
		value := unsafe { input[3 + index] }
		if value < 0 || value >= 1_000_000_007 { return -1 }
		if index < matrix_count { matrix[index] = value } else { base_row[index - matrix_count] = value }
	}
	if nth_term < dimension_value - constant_or_sum_included {
		return base_row[int(nth_term - constant_or_sum_included)]
	}
	mut zero := true
	for index in 0 .. matrix_count { if matrix[index] != 0 { zero = false } }
	if zero { return 0 }
	result := matrix_power(matrix, dimension, nth_term - dimension_value + 1 + constant_or_sum_included)
	mut value := i64(0)
	for index in 0 .. dimension {
		value = (value + (base_row[index] % 1_000_000_007) *
			(result[index * dimension + dimension - 1] % 1_000_000_007) % 1_000_000_007) % 1_000_000_007
	}
	return value
}
