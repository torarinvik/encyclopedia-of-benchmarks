module stirling_number_of_the_second_kind_small_p_large_n

const max_n = i64(1000000000000000000)
const max_t = 8
const max_k = 8
const width = 9

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn stirling_value(n i64, k int, modulus i64) i64 {
	mut matrix := [81]i64{}
	mut squared := [81]i64{}
	mut vector := [9]i64{}
	mut next_vector := [9]i64{}
	dimension := k + 1
	for index in 0 .. dimension {
		matrix[index * width + index] = i64(index) % modulus
		if index > 0 { matrix[index * width + index - 1] = 1 }
	}
	vector[0] = 1

	mut exponent := n
	for exponent > 0 {
		if exponent % 2 != 0 {
			for row in 0 .. dimension {
				mut total := i64(0)
				for column in 0 .. dimension {
					total = (total + matrix[row * width + column] * vector[column]) % modulus
				}
				next_vector[row] = total
			}
			for row in 0 .. dimension { vector[row] = next_vector[row] }
		}
		exponent /= 2
		if exponent > 0 {
			for row in 0 .. dimension {
				for column in 0 .. dimension {
					mut total := i64(0)
					for inner in 0 .. dimension {
						total = (total + matrix[row * width + inner] * matrix[inner * width + column]) % modulus
					}
					squared[row * width + column] = total
				}
			}
			for row in 0 .. dimension {
				for column in 0 .. dimension {
					matrix[row * width + column] = squared[row * width + column]
					squared[row * width + column] = 0
				}
			}
		}
	}
	return vector[k]
}

@[export: 'stirling_number_of_the_second_kind_small_p_large_n']
pub fn stirling_number_of_the_second_kind_small_p_large_n(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 18 { return -1 }
		count_value := input[0]
		modulus := input[1]
		if count_value < 1 || count_value > max_t { return -1 }
		if length != usize(2 + 2 * count_value) || modulus < 11 || modulus > 97 || !is_prime(modulus) { return -1 }

		mut result := i64(0)
		for case_index in 0 .. int(count_value) {
			n := input[2 + 2 * case_index]
			k_value := input[3 + 2 * case_index]
			if n < 0 || n > max_n || k_value < 0 || k_value > max_k || k_value > n { return -1 }
			value := stirling_value(n, int(k_value), modulus)
			next := i64(case_index + 1)
			result = (result + next * next * value) % modulus
		}
		return result
	}
}
