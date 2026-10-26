module first_fit_cardinality_bin_packing

fn put_i64(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'first_fit_cardinality_bin_packing']
pub fn first_fit_cardinality_bin_packing(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 35 { return -1 }
	unsafe {
		n0, limit, cap := input[0], input[1], input[2]
		if n0 < 1 || n0 > 32 || limit < 1 || limit > 32 || cap < 1 || cap > 10000 || length != usize(n0 + 3) { return -1 }
		n := int(n0)
		for i in 0 .. n { if input[3+i] < 1 || input[3+i] > cap { return -1 } }
		mut loads := []i64{len: 32, init: 0}; mut used := []i64{len: 32, init: 0}; mut owners := []i64{len: 32, init: 0}
		mut bins := 0
		for i in 0 .. n {
			size := input[3+i]
			mut b := 0
			for b < bins && (used[b] >= limit || loads[b] > cap-size) { b++ }
			if b == bins { bins++ }
			loads[b] += size; used[b]++; owners[i] = i64(b)
		}
		bytes := 8 * (n + 1)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, i64(bins))
		for i in 0 .. n { put_i64(mut output, i+1, owners[i]) }
		return i64(bytes)
	}
}
