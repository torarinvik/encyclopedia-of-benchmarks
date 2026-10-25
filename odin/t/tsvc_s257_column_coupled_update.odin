package tsvc_s257_column_coupled_update

import "core:c"

MAX_N :: 8
MAX_PASSES :: 4

@(export)
tsvc_s257_column_coupled_update :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 12 || length > 2 + MAX_N + 2 * MAX_N * MAX_N do return -1
	n_value, passes_value := values[0], values[1]
	if n_value < 2 || n_value > MAX_N || passes_value < 1 || passes_value > MAX_PASSES do return -1
	n, passes := int(n_value), int(passes_value)
	if length != c.size_t(2 + n + 2 * n * n) do return -1
	for index := c.size_t(2); index < length; index += 1 {
		if values[index] < -1 || values[index] > 1 do return -1
	}

	var a: [MAX_N]i64
	var aa, bb: [MAX_N * MAX_N]i64
	for i := 0; i < n; i += 1 { a[i] = values[2+i] }
	aa_start := 2 + n
	bb_start := aa_start + n * n
	for i := 0; i < n * n; i += 1 {
		aa[i] = values[aa_start+i]
		bb[i] = values[bb_start+i]
	}
	for _ in 0..<passes {
		for i := 1; i < n; i += 1 {
			for j := 0; j < n; j += 1 {
				cell := j*n + i
				a[i] = aa[cell] - a[i-1]
				aa[cell] = a[i] + bb[cell]
			}
		}
	}
	checksum: i64 = 0
	for i := 0; i < n; i += 1 { checksum += a[i] }
	for i := 0; i < n*n; i += 1 { checksum += aa[i] }
	return checksum
}
