package ekg_sequence

import "core:c"

MAX_N :: 8
MAX_CANDIDATE :: 40320

gcd_i64 :: proc(left, right: i64) -> i64 {
	a, b := left, right
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

@(export)
ekg_sequence :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 2 do return -1
	requested := input[0]
	if length != 1 || requested < 1 || requested > MAX_N do return -1

	terms: [MAX_N]i64 = {}
	used: [MAX_CANDIDATE + 1]u8 = {}
	terms[0] = 1
	used[1] = 1
	term_count := 1
	if requested >= 2 {
		terms[1] = 2
		used[2] = 1
		term_count = 2
	}

	for term_count < int(requested) {
		position := i64(term_count + 1)
		previous := terms[term_count - 1]
		search_bound := previous * position
		candidate: i64 = 1
		for candidate <= search_bound {
			if used[int(candidate)] == 0 && gcd_i64(previous, candidate) > 1 do break
			candidate += 1
		}
		if candidate > search_bound do return -1
		terms[term_count] = candidate
		used[int(candidate)] = 1
		term_count += 1
	}

	output_bytes := int(requested) * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < term_count; index += 1 {
		bits := u64(terms[index])
		for byte := 0; byte < 8; byte += 1 {
			output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255)
		}
	}
	return i64(output_bytes)
}
