package stirling_number_of_the_second_kind_small_p_large_n

import "core:c"

MAX_N :: i64(1000000000000000000)
MAX_T :: 8
MAX_K :: 8
WIDTH :: 9

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 1
	}
	return true
}

stirling_value :: proc(n: i64, k: int, modulus: i64) -> i64 {
	matrix := [81]i64{}
	squared := [81]i64{}
	vector := [9]i64{}
	next_vector := [9]i64{}
	dimension := k + 1
	for index := 0; index < dimension; index += 1 {
		matrix[index * WIDTH + index] = i64(index) % modulus
		if index > 0 do matrix[index * WIDTH + index - 1] = 1
	}
	vector[0] = 1

	exponent := n
	for exponent > 0 {
		if exponent % 2 != 0 {
			for row := 0; row < dimension; row += 1 {
				total := i64(0)
				for column := 0; column < dimension; column += 1 {
					total = (total + matrix[row * WIDTH + column] * vector[column]) % modulus
				}
				next_vector[row] = total
			}
			for row := 0; row < dimension; row += 1 do vector[row] = next_vector[row]
		}
		exponent /= 2
		if exponent > 0 {
			for row := 0; row < dimension; row += 1 {
				for column := 0; column < dimension; column += 1 {
					total := i64(0)
					for inner := 0; inner < dimension; inner += 1 {
						total = (total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column]) % modulus
					}
					squared[row * WIDTH + column] = total
				}
			}
			for row := 0; row < dimension; row += 1 {
				for column := 0; column < dimension; column += 1 {
					matrix[row * WIDTH + column] = squared[row * WIDTH + column]
					squared[row * WIDTH + column] = 0
				}
			}
		}
	}
	return vector[k]
}

@(export)
stirling_number_of_the_second_kind_small_p_large_n :: proc "c" (input: [^]i64,
	length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 18 do return -1
	count_value := input[0]
	modulus := input[1]
	if count_value < 1 || count_value > MAX_T do return -1
	if length != c.size_t(2 + 2 * count_value) do return -1
	if modulus < 11 || modulus > 97 || !is_prime(modulus) do return -1

	result := i64(0)
	for case_index := 0; case_index < int(count_value); case_index += 1 {
		n := input[2 + 2 * case_index]
		k_value := input[3 + 2 * case_index]
		if n < 0 || n > MAX_N || k_value < 0 || k_value > MAX_K || k_value > n do return -1
		value := stirling_value(n, int(k_value), modulus)
		next := i64(case_index + 1)
		result = (result + next * next * value) % modulus
	}
	return result
}
