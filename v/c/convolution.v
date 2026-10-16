module convolution

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'convolution']
pub fn convolution(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 4 || length > 130 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_a := values[0]
		raw_b := values[1]
		if raw_a < 1 || raw_a > 64 || raw_b < 1 || raw_b > 64 { return -1 }
		a_count := int(raw_a)
		b_count := int(raw_b)
		if length != usize(a_count + b_count + 2) { return -1 }
		for j in 0 .. a_count + b_count {
			if values[j+2] < -1_000_000 || values[j+2] > 1_000_000 { return -1 }
		}
		result_count := a_count + b_count - 1
		byte_count := result_count * 8
		if unsafe { output == nil } || capacity < usize(byte_count) { return -2 }
		for i in 0 .. result_count {
			k_start := if i >= b_count - 1 { i - (b_count - 1) } else { 0 }
			k_end := if i < a_count { i } else { a_count - 1 }
			mut sum := i64(0)
			for k := k_start; k <= k_end; k++ { sum += values[k+2] * values[a_count+(i-k)+2] }
			store_i64_le(mut output, i*8, sum)
		}
		return i64(byte_count)
	}
}
