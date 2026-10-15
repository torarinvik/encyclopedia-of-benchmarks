package collatz_sequence

import "core:c"

MAX_START :: 1_000_000

next_term :: proc "contextless" (value: i64) -> i64 {
	if value % 2 == 0 do return value / 2
	return 3 * value + 1
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + c.size_t(byte)] = u8((bits >> (byte * 8)) & 0xff)
	}
}

@(export)
collatz_sequence :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 1 || input[0] < 1 || input[0] > MAX_START do return -1
	current := input[0]
	term_count := c.size_t(1)
	for current != 1 { current = next_term(current); term_count += 1 }
	required := term_count * 8
	if output_capacity < required do return -2
	current = input[0]
	written := c.size_t(0)
	for {
		store_i64_le(output, written, current)
		written += 8
		if current == 1 do break
		current = next_term(current)
	}
	return i64(written)
}
