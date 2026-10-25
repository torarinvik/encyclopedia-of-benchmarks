package tsvc_s342_conditional_unpack

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 2 * MAX_N
MAX_VALUE :: i64(2)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
tsvc_s342_conditional_unpack :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if int(length) != 1 + 2 * n do return -1

	a_start := 1
	b_start := a_start + n
	var a: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[a_start + i]
		if a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
			input[b_start + i] < -MAX_VALUE || input[b_start + i] > MAX_VALUE do return -1
	}
	if output == nil || output_capacity < c.size_t(8 * n) do return -2

	packed_index := 0
	for i := 0; i < n; i += 1 {
		if a[i] > 0 {
			a[i] = input[b_start + packed_index]
			packed_index += 1
		}
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
