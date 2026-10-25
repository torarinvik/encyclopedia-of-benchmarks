package tsvc_s244_false_dependence_cycle_break

import "core:c"

// Clean-room port of TSVC s244; see package README for provenance and rights.
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s244_false_dependence_cycle_break :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 9 || length > 129 do return -1
	if input[0] < 2 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	var a, b, c, d: [MAX_N]i64
	var trace: [MAX_N - 1]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[1 + i]
		b[i] = input[1 + n + i]
		c[i] = input[1 + 2 * n + i]
		d[i] = input[1 + 3 * n + i]
		if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
			c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 do return -1
	}
	output_values := 3 * n - 1
	if output == nil || capacity < c.size_t(8 * output_values) do return -2
	for i := 0; i < n - 1; i += 1 {
		a[i] = b[i] + c[i] * d[i]
		b[i] = c[i] + b[i]
		a[i + 1] = b[i] + a[i + 1] * d[i]
		trace[i] = a[i + 1]
	}
	offset := 0
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * offset, a[i]); offset += 1 }
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * offset, b[i]); offset += 1 }
	for i := 0; i < n - 1; i += 1 { store_i64_le(output, 8 * offset, trace[i]); offset += 1 }
	return i64(output_values)
}
