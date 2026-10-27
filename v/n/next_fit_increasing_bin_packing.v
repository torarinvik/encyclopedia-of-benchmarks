module next_fit_increasing_bin_packing

fn put_i64(mut output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'next_fit_increasing_bin_packing']
pub fn next_fit_increasing_bin_packing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > 65 { return -1 }
	unsafe {
		n0 := input[0]
		if n0 < 0 || n0 > 64 || length != usize(1+n0) { return -1 }
		n := int(n0)
		for i in 0 .. n { if input[i+1] < 1 || input[i+1] > 1000000 { return -1 } }
		mut order := [64]int{}
		mut assignments := [64]i64{}
		for i in 0 .. n { order[i] = i }
		// Stable ascending insertion sort preserves original order on equal sizes.
		for i in 1 .. n {
			item := order[i]
			mut j := i
			for j > 0 && input[order[j-1]+1] > input[item+1] { order[j] = order[j-1]; j-- }
			order[j] = item
		}
		mut bins := i64(0)
		mut remaining := i64(0)
		for rank in 0 .. n {
			item := order[rank]
			size := input[item+1]
			if bins == 0 || size > remaining { assignments[item] = bins; bins++; remaining = 1000000-size }
			else { assignments[item] = bins-1; remaining -= size }
		}
		bytes := 8*(n+1)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, bins)
		for i in 0 .. n { put_i64(mut output, i+1, assignments[i]) }
		return i64(bytes)
	}
}
