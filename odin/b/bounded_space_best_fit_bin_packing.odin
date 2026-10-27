package bounded_space_best_fit_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

bounded_space_best_fit_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 65 do return -1
	n0 := input[0]
	if n0 < 0 || n0 > 64 || length != c.size_t(1+n0) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[i+1] < 1 || input[i+1] > 1000000 do return -1 }
	var loads: [64]i64
	var assignments: [64]i64
	var open: [64]bool
	bins := 0
	for item := 0; item < n; item += 1 {
		size := input[item+1]
		selected := bins
		least_remaining: i64 = 1000001
		for bin := 0; bin < bins; bin += 1 {
			if open[bin] && loads[bin]+size <= 1000000 {
				remaining := 1000000-loads[bin]-size
				if remaining < least_remaining { least_remaining = remaining; selected = bin }
			}
		}
		if selected == bins {
			loads[bins] = size; open[bins] = size < 1000000; assignments[item] = i64(bins); bins += 1
		} else {
			loads[selected] += size; assignments[item] = i64(selected)
			if loads[selected] == 1000000 { open[selected] = false }
		}
		partial_open := 0
		for bin := 0; bin < bins; bin += 1 { if open[bin] { partial_open += 1 } }
		for partial_open > 2 {
			weakest := bins
			for bin := 0; bin < bins; bin += 1 {
				if open[bin] && (weakest == bins || loads[bin] < loads[weakest] || (loads[bin] == loads[weakest] && bin > weakest)) { weakest = bin }
			}
			open[weakest] = false; partial_open -= 1
		}
	}
	bytes := 8*(n+1)
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(bins))
	for item := 0; item < n; item += 1 { put_i64(output, item+1, assignments[item]) }
	return i64(bytes)
}
