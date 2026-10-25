package tsvc_s273_dependent_conditional_update

import "core:c"

MAX_N :: 64
MAX_PASSES :: 8

@(export)
tsvc_s273_dependent_conditional_update :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 7 || length > 2 + 5 * MAX_N do return -1
	n_value, passes_value := values[0], values[1]
	if n_value < 1 || n_value > MAX_N || passes_value < 1 || passes_value > MAX_PASSES do return -1
	n, passes := int(n_value), int(passes_value)
	if length != c.size_t(2 + 5*n) do return -1
	for index := c.size_t(2); index < length; index += 1 {
		if values[index] < -2 || values[index] > 2 do return -1
	}
	var a, b, cc, d, e: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = values[2+i]
		b[i] = values[2+n+i]
		cc[i] = values[2+2*n+i]
		d[i] = values[2+3*n+i]
		e[i] = values[2+4*n+i]
	}
	for _ in 0..<passes {
		for i := 0; i < n; i += 1 {
			a[i] += d[i]*e[i]
			if a[i] < 0 do b[i] += d[i]*e[i]
			cc[i] += a[i]*d[i]
		}
	}
	checksum: i64 = 0
	for i := 0; i < n; i += 1 { checksum += a[i] + b[i] + cc[i] }
	return checksum
}
