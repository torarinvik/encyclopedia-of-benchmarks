package tsvc_s442_indexed_square_accumulate

import "core:c"

// Clean-room bounded port of TSVC s442; see package README for provenance.
MAX_N :: 64
MAX_PASSES :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s442_indexed_square_accumulate :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 8 || length > 386 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_PASSES do return -1
	n := int(input[0])
	passes := int(input[1])
	if length != c.size_t(2 + 6 * n) do return -1
	var a, b, c, d, e, selector: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[2 + i]
		b[i] = input[2 + n + i]
		c[i] = input[2 + 2 * n + i]
		d[i] = input[2 + 3 * n + i]
		e[i] = input[2 + 4 * n + i]
		selector[i] = input[2 + 5 * n + i]
		if a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
			c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 ||
			e[i] < -2 || e[i] > 2 || selector[i] < 1 || selector[i] > 4 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	for round := 0; round < passes; round += 1 {
		for i := 0; i < n; i += 1 {
			selected := b[i]
			if selector[i] == 2 { selected = c[i] }
			if selector[i] == 3 { selected = d[i] }
			if selector[i] == 4 { selected = e[i] }
			a[i] += selected * selected
		}
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
