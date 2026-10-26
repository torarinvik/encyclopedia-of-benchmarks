module approximate_tandem_squares

fn put_i64(mut output &u8, at int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[at * 8 + b] = u8((bits >> u64(8 * b)) & 255) } }
}

@[export: 'approximate_tandem_squares']
pub fn approximate_tandem_squares(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 34 { return -1 }
	unsafe {
		n0, budget := input[0], input[1]
		if n0 < 2 || n0 > 32 || budget < 0 || budget > 8 || length != usize(n0 + 2) { return -1 }
		n := int(n0)
		for i in 0 .. n { if input[2 + i] < 0 || input[2 + i] > 3 { return -1 } }
		mut records := []i64{len: 768, init: 0}
		mut count := 0
		for start in 0 .. n {
			mut period := 1
			for 2 * period <= n - start {
				mut mismatches := i64(0)
				for i in 0 .. period { if input[2 + start + i] != input[2 + start + period + i] { mismatches++ } }
				if mismatches <= budget {
					records[3 * count] = i64(start); records[3 * count + 1] = i64(period); records[3 * count + 2] = mismatches
					count++
				}
				period++
			}
		}
		bytes := 8 * (1 + 3 * count)
		if output == nil || capacity < usize(bytes) { return -2 }
		put_i64(mut output, 0, i64(count))
		for i in 0 .. 3 * count { put_i64(mut output, 1 + i, records[i]) }
		return i64(bytes)
	}
}
