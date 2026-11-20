package yellowstone_permutation_prefix

import "core:c"

MAX_N :: 64
MIN_CAP :: 3
MAX_CAP :: 256
MAX_PARSEABLE_LENGTH :: 3

ypp_gcd :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

ypp_construct :: proc(requested, candidate_cap: i64) -> i64 {
	terms: [64]i64 = {}
	used: [257]bool = {}
	terms[0] = 1
	terms[1] = 2
	terms[2] = 3
	if requested <= 3 do return terms[int(requested - 1)]
	used[1] = true
	used[2] = true
	used[3] = true

	term_count := 3
	for term_count < int(requested) {
		two_back := terms[term_count - 2]
		previous := terms[term_count - 1]
		candidate: i64 = 1
		for candidate <= candidate_cap {
			if !used[int(candidate)] && ypp_gcd(candidate, two_back) > 1 && ypp_gcd(candidate, previous) == 1 do break
			candidate += 1
		}
		if candidate > candidate_cap do return -1
		terms[term_count] = candidate
		used[int(candidate)] = true
		term_count += 1
	}
	return terms[int(requested - 1)]
}

@(export)
yellowstone_permutation_prefix :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	if length != 2 do return -1
	requested := input[0]
	candidate_cap := input[1]
	if requested < 1 || requested > i64(MAX_N) || candidate_cap < i64(MIN_CAP) || candidate_cap > i64(MAX_CAP) do return -1
	return ypp_construct(requested, candidate_cap)
}
