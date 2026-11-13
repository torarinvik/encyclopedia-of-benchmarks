module pfaffian_of_matrix

const max_n = 8
const max_dimension = 16
const max_parseable = 258
const modulus = i64(998244353)

fn normalize(value i64) i64 {
	result := value % modulus
	return if result < 0 { result + modulus } else { result }
}

fn multiply(left i64, right i64) i64 { return (left * right) % modulus }

fn power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = multiply(result, base) }
		base = multiply(base, base)
		exponent >>= 1
	}
	return result
}

@[export: 'pfaffian_of_matrix']
pub fn pfaffian_of_matrix(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_parseable { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		dimension := int(2 * input[0])
		if length != usize(1 + dimension * dimension) { return -1 }
		mut matrix := []i64{len: max_dimension * max_dimension}
		for row in 0 .. dimension {
			for column in 0 .. dimension {
				value := input[1 + row * dimension + column]
				if value < 0 || value >= modulus { return -1 }
				matrix[row * max_dimension + column] = value
			}
		}
		for row in 0 .. dimension {
			if matrix[row * max_dimension + row] != 0 { return -1 }
			for column in row + 1 .. dimension {
				if (matrix[row * max_dimension + column] + matrix[column * max_dimension + row]) % modulus != 0 {
					return -1
				}
			}
		}

		mut result := i64(1)
		for pivot_index in 0 .. dimension {
			if pivot_index % 2 != 0 { continue }
			mut partner := pivot_index + 1
			for partner < dimension && matrix[pivot_index * max_dimension + partner] == 0 { partner++ }
			if partner == dimension { return 0 }
			if partner != pivot_index + 1 {
				swapped := pivot_index + 1
				for k in 0 .. dimension {
					matrix[swapped * max_dimension + k], matrix[partner * max_dimension + k] = matrix[partner * max_dimension + k], matrix[swapped * max_dimension + k]
				}
				for k in 0 .. dimension {
					matrix[k * max_dimension + swapped], matrix[k * max_dimension + partner] = matrix[k * max_dimension + partner], matrix[k * max_dimension + swapped]
				}
				if result != 0 { result = modulus - result }
			}
			first, second := pivot_index * max_dimension, (pivot_index + 1) * max_dimension
			pivot := matrix[first + pivot_index + 1]
			result = multiply(result, pivot)
			inverse := power(pivot, modulus - 2)
			for row in pivot_index + 2 .. dimension {
				for column in row + 1 .. dimension {
					cross := normalize(multiply(matrix[first + row], matrix[second + column]) -
						multiply(matrix[first + column], matrix[second + row]))
					value := normalize(matrix[row * max_dimension + column] - multiply(cross, inverse))
					matrix[row * max_dimension + column] = value
					matrix[column * max_dimension + row] = if value == 0 { 0 } else { modulus - value }
				}
			}
		}
		return result
	}
}
