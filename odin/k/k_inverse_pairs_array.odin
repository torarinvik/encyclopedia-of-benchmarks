package k_inverse_pairs_array

import "core:c"

MAX_N :: 128
MAX_K :: 512
MODULUS :: i64(1_000_000_007)

@(export)
k_inverse_pairs_array :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 3 || int(length) != 2 do return -1
	n_value, k_value := input[0], input[1]
	if n_value < 0 || n_value > MAX_N || k_value < 0 || k_value > MAX_K do return -1
	n, k := int(n_value), int(k_value)
	max_inversions := 0
	if n > 0 do max_inversions = n * (n - 1) / 2
	if k > max_inversions do return 0

	previous: [MAX_K + 1]i64
	current: [MAX_K + 1]i64
	previous = {}
	current = {}
	previous[0] = 1
	for size := 1; size <= n; size += 1 {
		window := i64(0)
		for inversions := 0; inversions <= k; inversions += 1 {
			window += previous[inversions]
			if inversions >= size do window -= previous[inversions - size]
			window %= MODULUS
			if window < 0 do window += MODULUS
			current[inversions] = window
		}
		for inversions := 0; inversions <= k; inversions += 1 {
			previous[inversions] = current[inversions]
			current[inversions] = 0
		}
	}
	return previous[k]
}
