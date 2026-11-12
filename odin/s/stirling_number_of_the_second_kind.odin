package stirling_number_of_the_second_kind

import "core:c"

MAX_N :: 16
MODULUS :: i64(998244353)

@(export)
stirling_number_of_the_second_kind :: proc "c" (input: [^]i64,
	length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_N do return -1
	n := int(n_value)

	row := [17]i64{}
	row[0] = 1
	for current_n := 1; current_n <= n; current_n += 1 {
		for k := current_n; k > 0; k -= 1 {
			row[k] = (row[k - 1] + i64(k) * row[k]) % MODULUS
		}
		row[0] = 0
	}

	result := i64(0)
	for k := 0; k <= n; k += 1 {
		next := i64(k + 1)
		weight := next * next * next
		result = (result + weight * row[k]) % MODULUS
	}
	return result
}
