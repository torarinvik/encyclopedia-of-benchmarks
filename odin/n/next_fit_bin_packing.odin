package next_fit_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

next_fit_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 65 do return -1
	n0 := input[0]
	if n0 < 0 || n0 > 64 || length != c.size_t(1+n0) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[i+1] < 1 || input[i+1] > 1000000 do return -1 }
	assignments: [64]i64
	bins: i64 = 0
	remaining: i64 = 0
	for i := 0; i < n; i += 1 {
		size := input[i+1]
		if bins == 0 || size > remaining { assignments[i] = bins; bins += 1; remaining = 1000000-size }
		else { assignments[i] = bins-1; remaining -= size }
	}
	bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, bins)
	for i := 0; i < n; i += 1 { put_i64(output, i+1, assignments[i]) }
	return i64(bytes)
}
