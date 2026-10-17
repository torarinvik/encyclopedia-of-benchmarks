module sherman_morrison

const max_dimension = 4
const max_input_length = 26
const max_output_elements = 16

@[export: 'sherman_morrison']
pub fn sherman_morrison(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > max_input_length { return -1 }
		dimension_value := input[0]
		if !dimension_value.is_finite() || dimension_value < 1.0 || dimension_value > f64(max_dimension) ||
			f64(int(dimension_value)) != dimension_value { return -1 }
		dimension := int(dimension_value)
		expected_length := 1 + dimension*dimension + 2*dimension
		if input_length != usize(expected_length) { return -1 }

		mut coefficients := [max_output_elements + 2*max_dimension]f64{}
		for index in 0 .. expected_length - 1 {
			value := input[1 + index]
			if !value.is_finite() || value < -2.0 || value > 2.0 || f64(int(value)) != value { return -1 }
			coefficients[index] = value
		}

		matrix_elements := dimension*dimension
		mut matrix := [max_dimension][max_dimension]f64{}
		mut u := [max_dimension]f64{}
		mut v := [max_dimension]f64{}
		for row in 0 .. dimension {
			for column in 0 .. dimension { matrix[row][column] = coefficients[row*dimension+column] }
		}
		for index in 0 .. dimension {
			u[index] = coefficients[matrix_elements+index]
			v[index] = coefficients[matrix_elements+dimension+index]
		}

		mut right := [max_dimension]f64{}
		for column in 0 .. dimension {
			for inner in 0 .. dimension { right[column] += v[inner] * matrix[inner][column] }
		}
		mut denominator := f64(0.0)
		for inner in 0 .. dimension { denominator += right[inner] * u[inner] }
		denominator += 1.0

		mut updated := [max_output_elements]f64{}
		if denominator != 0.0 {
			mut left := [max_dimension]f64{}
			for row in 0 .. dimension {
				for inner in 0 .. dimension { left[row] += matrix[row][inner] * u[inner] }
			}
			reciprocal := 1.0 / denominator
			for row in 0 .. dimension {
				for column in 0 .. dimension {
					outer_product := left[row] * right[column]
					scaled_product := outer_product * reciprocal
					updated[row*dimension+column] = matrix[row][column] - scaled_product
				}
			}
		}
		if output == nil { return -2 }
		if denominator == 0.0 { return 0 }
		if output_capacity < usize(dimension*dimension) { return -2 }
		for index in 0 .. dimension*dimension { output[index] = updated[index] }
		return i64(dimension * dimension)
	}
}
