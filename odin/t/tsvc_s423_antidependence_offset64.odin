package tsvc_s423_antidependence_offset64

import "core:c"

@(export)
tsvc_s423_antidependence_offset64 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 130 || length > 193 do return -1
	if input[0] < 65 || input[0] > 128 do return -1
	n := int(input[0])
	if length != c.size_t(n+65) do return -1
	a: [128]i64
	x: [192]i64
	for i := 0; i < 128; i += 1 { a[i] = 0 }
	for i := 0; i < 192; i += 1 { x[i] = 0 }
	for i := 0; i < n; i += 1 {
		a[i] = input[1+i]
		if a[i] < 0 || a[i] > 2 do return -1
	}
	for i := 0; i < 64; i += 1 {
		x[i] = input[1+n+i]
		if x[i] < 0 || x[i] > 2 do return -1
	}
	for i := 64; i < n+64; i += 1 { x[i] = 1 }
	for i := 0; i < n-1; i += 1 { x[i+1] = x[i+64] + a[i] }
	total: i64 = 0
	for i := 0; i < n; i += 1 { total += x[i] }
	return total
}
