module determinant

const max_dimension = 6
const max_input_length = 1 + max_dimension * max_dimension
const invalid_result = i64(-9223372036854775807 - 1)

fn determinant_recursive(matrix &i64, dimension int) i64 {
	if dimension == 1 { unsafe { return matrix[0] } }
	mut result := i64(0)
	mut minor := [25]i64{}
	for column in 0 .. dimension {
		mut minor_index := 0
		for row in 1 .. dimension {
			for source_column in 0 .. dimension {
				if source_column != column {
					unsafe { minor[minor_index] = matrix[row * dimension + source_column] }
					minor_index++
				}
			}
		}
		term := unsafe { matrix[column] } * determinant_recursive(&minor[0], dimension - 1)
		if column % 2 == 0 { result += term } else { result -= term }
	}
	return result
}

@[export: 'determinant']
pub fn determinant(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return invalid_result }
	unsafe {
		dimension_value := input[0]
		if dimension_value < 1 || dimension_value > max_dimension { return invalid_result }
		dimension := int(dimension_value)
		if length != usize(1 + dimension * dimension) { return invalid_result }
		for index in 0 .. dimension * dimension {
			if input[1 + index] < -9 || input[1 + index] > 9 { return invalid_result }
		}
		return determinant_recursive(&input[1], dimension)
	}
}
