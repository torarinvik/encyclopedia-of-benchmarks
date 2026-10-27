package next_fit_decreasing_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

next_fit_decreasing_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 65 do return -1
	n0 := input[0]
	if n0 < 0 || n0 > 64 || length != c.size_t(1+n0) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[i+1] < 1 || input[i+1] > 1000000 do return -1 }
	order: [64]int
	assignments: [64]i64
	for i := 0; i < n; i += 1 { order[i] = i }
	// Stable descending insertion sort; original indices remain in equal-size order.
	for i := 1; i < n; i += 1 {
		item := order[i]
		j := i
		for j > 0 && input[order[j-1]+1] < input[item+1] { order[j] = order[j-1]; j -= 1 }
		order[j] = item
	}
	bins: i64 = 0
	remaining: i64 = 0
	for rank := 0; rank < n; rank += 1 {
		item := order[rank]
		size := input[item+1]
		if bins == 0 || size > remaining { assignments[item] = bins; bins += 1; remaining = 1000000-size }
		else { assignments[item] = bins-1; remaining -= size }
	}
	bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, bins)
	for i := 0; i < n; i += 1 { put_i64(output, i+1, assignments[i]) }
	return i64(bytes)
}
