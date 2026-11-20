package fermat_factorization

import "core:c"

integer_sqrt_i64 :: proc(value, upper: i64) -> i64 {
	low: i64 = 0
	high := upper + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

@(export)
fermat_factorization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	number, max_steps := input[0], input[1]
	if number < 3 || number > 1_000_000_000_000 || number % 2 == 0 || max_steps < 0 || max_steps > 4096 do return -1
	candidate := integer_sqrt_i64(number, 1_000_000)
	if candidate * candidate < number { candidate += 1 }
	for step: i64 = 0; step < max_steps; step += 1 {
		difference := candidate * candidate - number
		root := integer_sqrt_i64(difference, candidate)
		if root * root == difference {
			factor := candidate - root
			if factor > 1 && factor < number do return factor
		}
		candidate += 1
	}
	return 0
}
