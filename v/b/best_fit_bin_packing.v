module best_fit_bin_packing

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'best_fit_bin_packing']
pub fn best_fit_bin_packing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > 65 { return -1 }
	unsafe {
		n0 := input[0]
		if n0 < 0 || n0 > 64 || length != usize(1+n0) { return -1 }
		n := int(n0)
		for i in 0 .. n { if input[i+1] < 1 || input[i+1] > 1000000 { return -1 } }
		mut loads := [64]i64{}
		mut assignments := [64]i64{}
		mut bins := 0
		for i in 0 .. n {
			size := input[i+1]
			mut selected := bins
			mut least_remaining := i64(1000001)
			for bin in 0 .. bins {
				if loads[bin] + size <= 1000000 {
					remaining := 1000000 - loads[bin] - size
					if remaining < least_remaining { least_remaining = remaining; selected = bin }
				}
			}
			if selected == bins { loads[bins] = size; assignments[i] = i64(bins); bins++ }
			else { loads[selected] += size; assignments[i] = i64(selected) }
		}
		bytes := 8 * (n + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, i64(bins))
		for i in 0 .. n { put_i64(mut output, i + 1, assignments[i]) }
		return i64(bytes)
	}
}
