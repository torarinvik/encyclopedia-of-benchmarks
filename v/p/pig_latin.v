@[export: 'pig_latin']
pub fn pig_latin(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != usize(v[0] + 1) { return -1 }
		count := int(v[0]); if count == 0 { return 0 }
		if count + 3 > int(capacity) || output == nil { return -2 }
		mut pivot := count
		for i in 0 .. count {
			mut x := v[i + 1]; if x >= 65 && x <= 90 { x += 32 }
			if x < 97 || x > 122 { return -1 }
			output[i] = u8(x)
			if pivot == count && (x == 97 || x == 101 || x == 105 || x == 111 || x == 117) { pivot = i }
		}
		if pivot == count { return -1 }
		if pivot == 0 { output[count] = 119; output[count + 1] = 97; output[count + 2] = 121; return i64(count + 3) }
		for i in 0 .. pivot { output[count + i] = output[i] }
		for i in 0 .. count - pivot { output[i] = output[pivot + i] }
		output[count] = 97; output[count + 1] = 121
		return i64(count + 2)
	}
}
