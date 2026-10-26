// Clean-room port of TSVC s1281; see the package README for provenance and rights.

package tsvc_s1281_elementwise_dual_update

import "core:c"

MAX_N :: 16
MAX_INPUT_LENGTH :: 82

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s1281_elementwise_dual_update :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 7 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > 8 do return -1
	n := int(input[0])
	passes := int(input[1])
	if length != c.size_t(2 + 5 * n) do return -1

	var a: [MAX_N]f64
	var b: [MAX_N]f64
	var c_values: [MAX_N]f64
	var d_values: [MAX_N]f64
	var e_values: [MAX_N]f64
	for i := 0; i < n; i += 1 {
		av := input[2+i]
		bv := input[2+n+i]
		cv := input[2+2*n+i]
		dv := input[2+3*n+i]
		ev := input[2+4*n+i]
		if av < -1 || av > 1 || bv < -1 || bv > 1 || cv < -1 || cv > 1 || dv < -1 || dv > 1 || ev < -1 || ev > 1 do return -1
		a[i] = f64(av); b[i] = f64(bv); c_values[i] = f64(cv)
		d_values[i] = f64(dv); e_values[i] = f64(ev)
	}

	output_bytes := 16 * n
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for pass := 0; pass < passes; pass += 1 {
		for i := 0; i < n; i += 1 {
			x := b[i] * c_values[i] + a[i] * d_values[i] + e_values[i]
			a[i] = x - 1.0
			b[i] = x
		}
	}
	for i := 0; i < n; i += 1 {
		store_i64_le(output, 8*i, i64(a[i]))
		store_i64_le(output, 8*(n+i), i64(b[i]))
	}
	return i64(output_bytes)
}
