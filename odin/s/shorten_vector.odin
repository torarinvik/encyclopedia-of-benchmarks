package shorten_vector

import "core:c"

is_removed :: proc "contextless" (value: i64, input: [^]i64, n: int, by: int) -> bool {
	if by == 0 do return true
	for key := n - by; key < n; key += 1 {
		if value == input[2 + key] do return true
	}
	return false
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
shorten_vector :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 67 do return -1
	raw_n, raw_by := input[0], input[1]
	if raw_n < 0 || raw_n > 64 || raw_by < 0 || raw_by > raw_n do return -1
	n, by := int(raw_n), int(raw_by)
	if length != c.size_t(2+n) do return -1
	for i := 0; i < n; i += 1 {
		if input[2+i] < -1_000_000 || input[2+i] > 1_000_000 do return -1
	}

	survivor_count := 0
	for i := 0; i < n; i += 1 {
		if !is_removed(input[2+i], input, n, by) do survivor_count += 1
	}
	bytes := survivor_count * 8
	if output == nil || capacity < c.size_t(bytes) do return -2

	written := 0
	for i := 0; i < n; i += 1 {
		value := input[2+i]
		if !is_removed(value, input, n, by) {
			put_i64_le(output, written*8, value)
			written += 1
		}
	}
	return i64(bytes)
}
