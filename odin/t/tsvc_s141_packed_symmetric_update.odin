package tsvc_s141_packed_symmetric_update

import "core:c"

MAX_N :: 16
MAX_TRIANGLE :: MAX_N * (MAX_N + 1) / 2
MAX_INPUT_LENGTH :: 2 + MAX_TRIANGLE + MAX_N * MAX_N
MAX_VALUE :: i64(1_000_000)
MAX_ROUNDS :: 32

bounded_value :: proc "contextless" (value: i64) -> bool {
	return value >= -MAX_VALUE && value <= MAX_VALUE
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s141_packed_symmetric_update :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw, rounds_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_N || rounds_raw < 1 || rounds_raw > MAX_ROUNDS do return -1
	n := int(n_raw)
	triangle := n * (n + 1) / 2
	matrix_start := 2 + triangle
	if int(length) != matrix_start + n * n do return -1

	var packed: [MAX_TRIANGLE]i64
	for p := 0; p < triangle; p += 1 {
		packed[p] = input[2 + p]
		if !bounded_value(packed[p]) do return -1
	}
	for p := 0; p < n * n; p += 1 {
		if !bounded_value(input[matrix_start + p]) do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * triangle) do return -2

	for round := 0; round < int(rounds_raw); round += 1 {
		for i := 0; i < n; i += 1 {
			for j := i; j < n; j += 1 {
				k := j * (j + 1) / 2 + i
				packed[k] += input[matrix_start + j * n + i]
			}
		}
	}
	for p := 0; p < triangle; p += 1 { store_i64_le(output, 8 * p, packed[p]) }
	return i64(triangle)
}
