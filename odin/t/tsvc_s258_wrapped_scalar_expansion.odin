package tsvc_s258_wrapped_scalar_expansion

import "core:c"

// Clean-room port of TSVC s258; see package README for provenance and rights.
MAX_N :: 64

@(export)
tsvc_s258_wrapped_scalar_expansion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 257 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 4 * n) do return -1
	var a, c, d, aa0, b, e: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[1 + i]
		c[i] = input[1 + n + i]
		d[i] = input[1 + 2 * n + i]
		aa0[i] = input[1 + 3 * n + i]
		if a[i] < 0 || a[i] > 2 || c[i] < 0 || c[i] > 2 ||
			d[i] < 0 || d[i] > 2 || aa0[i] < 0 || aa0[i] > 2 do return -1
	}
	s: i64 = 0
	for i := 0; i < n; i += 1 {
		if a[i] > 0 { s = d[i] * d[i] }
		b[i] = s * c[i] + d[i]
		e[i] = (s + 1) * aa0[i]
	}
	sum_b, sum_e: i64 = 0
	for i := 0; i < n; i += 1 { sum_b += b[i]; sum_e += e[i] }
	return sum_b + sum_e
}
