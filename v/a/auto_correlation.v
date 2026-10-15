module auto_correlation

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'auto_correlation']
pub fn auto_correlation(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 65 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_count := values[0]
		if raw_count < 1 || raw_count > 64 { return -1 }
		count := int(raw_count)
		if length != usize(count + 1) { return -1 }
		for index in 0 .. count {
			if values[index + 1] < -1000000 || values[index + 1] > 1000000 { return -1 }
		}
		result_count := 2 * count - 1
		byte_count := 8 * result_count
		if unsafe { output == nil } || output_capacity < usize(byte_count) { return -2 }
		y_start := count
		for index in 0 .. result_count {
			if index < count { y_start -= 1 }
			k_min := if index >= count - 1 { index - (count - 1) } else { 0 }
			k_max := if index < count { index } else { count - 1 }
			mut offset := 0
			mut sum := i64(0)
			for k := k_min; k <= k_max; k++ {
				sum += values[k + 1] * values[y_start + offset + 1]
				offset++
			}
			store_i64_le(output, index * 8, sum)
		}
		return i64(byte_count)
	}
}
