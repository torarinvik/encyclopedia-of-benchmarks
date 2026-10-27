package sum_of_squares_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, word: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

sum_of_squares_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 66 do return -1
	capacity0, n0 := input[0], input[1]
	if capacity0 < 1 || capacity0 > 64 || n0 < 0 || n0 > 64 || length != c.size_t(2+n0) do return -1
	capacity, n := int(capacity0), int(n0)
	for i := 0; i < n; i += 1 { if input[i+2] < 1 || input[i+2] > capacity0 do return -1 }
	var histogram: [65]i64
	var loads: [64]i64
	var assignments: [64]i64
	bins := 0
	score: i64 = 0
	for item := 0; item < n; item += 1 {
		size := input[item+2]
		selected := bins
		best_score: i64 = 9223372036854775807
		for bin := 0; bin < bins; bin += 1 {
			from, to := loads[bin], loads[bin]+size
			if to > capacity0 do continue
			candidate := score
			if from < capacity0 { h := histogram[int(from)]; candidate += (h-1)*(h-1)-h*h }
			if to < capacity0 { h := histogram[int(to)]; candidate += (h+1)*(h+1)-h*h }
			if candidate < best_score { best_score = candidate; selected = bin }
		}
		new_score := score
		if size < capacity0 { h := histogram[int(size)]; new_score += (h+1)*(h+1)-h*h }
		if new_score < best_score { best_score = new_score; selected = bins }
		if selected == bins {
			loads[bins] = size; assignments[item] = i64(bins)
			if size < capacity0 { histogram[int(size)] += 1 }
			bins += 1
		} else {
			from, to := loads[selected], loads[selected]+size
			if from < capacity0 { histogram[int(from)] -= 1 }
			if to < capacity0 { histogram[int(to)] += 1 }
			loads[selected] = to; assignments[item] = i64(selected)
		}
		score = best_score
	}
	bytes := 8*(n+1)
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(bins))
	for item := 0; item < n; item += 1 { put_i64(output, item+1, assignments[item]) }
	return i64(bytes)
}
