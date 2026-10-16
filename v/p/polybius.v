module polybius

@[export: 'polybius']
pub fn polybius(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != usize(v[0] + 1) { return -1 }
		count := int(v[0]); needed := count * 2
		if needed > int(capacity) || (needed > 0 && output == nil) { return -2 }
		for i in 0 .. count {
			mut x := v[i + 1]
			if x >= 97 && x <= 122 { x -= 32 }
			if x < 65 || x > 90 || x == 74 { return -1 }
			mut index := x - 65
			if x > 74 { index-- }
			output[i * 2] = u8(65 + index / 5)
			output[i * 2 + 1] = u8(65 + index % 5)
		}
		return i64(needed)
	}
}
