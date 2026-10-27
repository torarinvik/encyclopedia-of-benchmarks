package first_fit_decreasing_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

first_fit_decreasing_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 65 do return -1
	n0 := input[0]
	if n0 < 0 || n0 > 64 || length != c.size_t(1+n0) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[i+1] < 1 || input[i+1] > 1000000 do return -1 }
	order: [64]int
	loads: [64]i64
	assignments: [64]i64
	for i := 0; i < n; i += 1 { order[i] = i }
	for i := 1; i < n; i += 1 {
		key := order[i]
		j := i
		for j > 0 && input[order[j-1]+1] < input[key+1] { order[j] = order[j-1]; j -= 1 }
		order[j] = key
	}
	bins := 0
	for pos := 0; pos < n; pos += 1 {
		item := order[pos]
		size := input[item+1]
		selected := 0
		for selected < bins && loads[selected]+size > 1000000 { selected += 1 }
		if selected == bins { loads[bins] = size; assignments[item] = i64(bins); bins += 1 }
		else { loads[selected] += size; assignments[item] = i64(selected) }
	}
	bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(bins))
	for i := 0; i < n; i += 1 { put_i64(output, i+1, assignments[i]) }
	return i64(bytes)
}
