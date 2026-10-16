module pairwise_iteration

@[export: 'pairwise_iteration']
pub fn pairwise_iteration(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != usize(v[0] + 1) { return -1 }
		count := int(v[0])
		for i in 0 .. count { if v[i + 1] < -1000000 || v[i + 1] > 1000000 { return -1 } }
		pairs := count - 1
		if pairs < 0 { pairs = 0 }
		needed := pairs * 16
		if needed > capacity || (needed > 0 && output == nil) { return -2 }
		mut k := 0
		for i in 0 .. pairs {
			for j in 0 .. 2 {
				bits := u64(v[i + j + 1])
				for b in 0 .. 8 { output[k] = u8((bits >> (8 * b)) & 255); k++ }
			}
		}
		return i64(needed)
	}
}
