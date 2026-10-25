package tsvc_s424_alias_overlap_feedback

import "core:c"

// Clean-room port of TSVC s424; see package README for provenance and rights.
MIN_N :: 66
MAX_N :: 192
X_LENGTH :: MAX_N + 63

@(export)
tsvc_s424_alias_overlap_feedback :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 130 || length > 256 do return -1
	if input[0] < MIN_N || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(n + 64) do return -1
	var a: [MAX_N]i64
	var x: [X_LENGTH]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[1 + i]
		if a[i] < 0 || a[i] > 10 do return -1
	}
	for i := 0; i < 63; i += 1 {
		x[i] = input[1 + n + i]
		if x[i] < 0 || x[i] > 10 do return -1
	}
	// The source's set1d on xx=array+63 clears the aliased view.
	for i := 63; i < X_LENGTH; i += 1 { x[i] = 0 }
	for i := 0; i < n - 1; i += 1 { x[i + 64] = x[i] + a[i] }
	checksum: i64 = 0
	for i := 0; i < n; i += 1 { checksum += x[63 + i] }
	return checksum
}
