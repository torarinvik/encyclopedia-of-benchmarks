const max_dimension = 8
const max_input_length = 65
const invalid_result = i64(-9223372036854775807) - 1

@[export: 'bareiss_determinant']
pub fn bareiss_determinant(input &i64, length usize) i64 {
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

		mut sign := i64(1)
		mut previous_pivot := i64(1)
		for k in 0 .. n-1 {
			if matrix[k*n+k] == 0 {
				mut replacement := k+1
				for replacement < n && matrix[replacement*n+k] == 0 { replacement++ }
				if replacement == n { return 0 }
				for column in 0 .. n {
					temporary := matrix[k*n+column]
					matrix[k*n+column] = matrix[replacement*n+column]
					matrix[replacement*n+column] = temporary
				}
				sign = -sign
			}
			pivot := matrix[k*n+k]
			for row in k+1 .. n {
				for column in k+1 .. n {
					numerator := matrix[row*n+column]*pivot - matrix[row*n+k]*matrix[k*n+column]
					matrix[row*n+column] = numerator / previous_pivot
				}
				matrix[row*n+k] = 0
			}
			previous_pivot = pivot
		}
		return sign * matrix[(n-1)*n+n-1]
	}
}
