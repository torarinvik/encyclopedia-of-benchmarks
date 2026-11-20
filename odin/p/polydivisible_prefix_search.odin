package polydivisible_prefix_search

import "core:c"

polydivisible_extend :: proc(prefix, digits, base, max_digits: i64) -> i64 {
	count := i64(1)
	if digits == max_digits do return count
	next_length := digits + 1
	for digit := i64(0); digit < base; digit += 1 {
		candidate := prefix * base + digit
		if candidate % next_length == 0 {
			count += polydivisible_extend(candidate, next_length, base, max_digits)
		}
	}
	return count
}

@(export)
polydivisible_prefix_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	base := input[0]
	max_digits := input[1]
	if base < 2 || base > 10 || max_digits < 1 || max_digits > 6 do return -1
	count := i64(0)
	for first_digit := i64(1); first_digit < base; first_digit += 1 {
		count += polydivisible_extend(first_digit, 1, base, max_digits)
	}
	return count
}
