package binomial_divisibility_primality_test

import "core:c"

@(export)
binomial_divisibility_primality_test :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n_value := input[0]
	if n_value < 2 || n_value > 1000 do return -1
	n := int(n_value)

	row: [1001]i64
	row[0] = 1
	for degree := 1; degree <= n; degree += 1 {
		row[degree] = 1
		for index := degree - 1; index > 0; index -= 1 {
			row[index] = (row[index] + row[index - 1]) % n_value
		}
	}
	for index := 1; index < n; index += 1 {
		if row[index] != 0 do return 0
	}
	return 1
}
