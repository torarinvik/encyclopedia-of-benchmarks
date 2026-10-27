module sum_of_squares_bin_packing

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'sum_of_squares_bin_packing']
pub fn sum_of_squares_bin_packing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 66 { return -1 }
	unsafe {
		capacity0, n0 := input[0], input[1]
		if capacity0 < 1 || capacity0 > 64 || n0 < 0 || n0 > 64 || length != usize(2 + n0) { return -1 }
		for i in 0 .. int(n0) { if input[i + 2] < 1 || input[i + 2] > capacity0 { return -1 } }
		mut histogram := [65]i64{}
		mut loads := [64]i64{}
		mut assignments := [64]i64{}
		mut bins := 0
		mut score := i64(0)
		for item in 0 .. int(n0) {
			size := input[item + 2]
			mut selected := bins
			mut best_score := i64(9223372036854775807)
			for bin in 0 .. bins {
				from, to := loads[bin], loads[bin] + size
				if to > capacity0 { continue }
				mut candidate := score
				if from < capacity0 { h := histogram[int(from)]; candidate += (h - 1) * (h - 1) - h * h }
				if to < capacity0 { h := histogram[int(to)]; candidate += (h + 1) * (h + 1) - h * h }
				if candidate < best_score { best_score = candidate; selected = bin }
			}
			mut new_score := score
			if size < capacity0 { h := histogram[int(size)]; new_score += (h + 1) * (h + 1) - h * h }
			if new_score < best_score { best_score = new_score; selected = bins }
			if selected == bins {
				loads[bins] = size; assignments[item] = i64(bins)
				if size < capacity0 { histogram[int(size)]++ }
				bins++
			} else {
				from, to := loads[selected], loads[selected] + size
				if from < capacity0 { histogram[int(from)]-- }
				if to < capacity0 { histogram[int(to)]++ }
				loads[selected] = to; assignments[item] = i64(selected)
			}
			score = best_score
		}
		bytes := 8 * (int(n0) + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, i64(bins))
		for item in 0 .. int(n0) { put_i64(mut output, item + 1, assignments[item]) }
		return i64(bytes)
	}
}
