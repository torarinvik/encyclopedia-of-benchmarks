package burnside_bracelets

import "core:c"

MAX_N :: 10
MAX_INPUT_VALUES :: 3
OUTPUT_BYTES :: 8

cycle_count :: proc(n, shift: int, reflection: bool) -> int {
	seen: [MAX_N]bool
	cycles := 0
	for start := 0; start < n; start += 1 {
		if seen[start] do continue
		cycles += 1
		position := start
		for !seen[position] {
			seen[position] = true
			if reflection { position = (shift + n - position) % n }
			else { position = (position + shift) % n }
		}
	}
	return cycles
}

fixed_colorings :: proc(n, shift: int, reflection: bool, colors: i64) -> i64 {
	cycles := cycle_count(n, shift, reflection)
	result := i64(1)
	for _ := 0; _ < cycles; _ += 1 { result *= colors }
	return result
}

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < OUTPUT_BYTES; byte += 1 {
		output[byte] = u8(bits >> (8 * byte))
	}
}

@(export)
burnside_bracelets :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	if length != 2 do return -1
	n_value := input[0]
	colors := input[1]
	if n_value < 1 || n_value > i64(MAX_N) || colors < 0 || colors > 3 do return -1
	n := int(n_value)

	fixed_sum := i64(0)
	for shift := 0; shift < n; shift += 1 {
		fixed_sum += fixed_colorings(n, shift, false, colors)
		fixed_sum += fixed_colorings(n, shift, true, colors)
	}
	answer := fixed_sum / i64(2 * n)
	if output == nil || capacity < OUTPUT_BYTES do return -2
	store_i64_le(output, answer)
	return OUTPUT_BYTES
}
