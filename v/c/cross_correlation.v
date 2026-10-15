module cross_correlation

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'cross_correlation']
pub fn cross_correlation(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 4 || length > 66 || unsafe { values == nil } { return -1 }
	unsafe {
		raw_x_count := values[0]
		raw_y_count := values[1]
		if raw_x_count < 1 || raw_x_count > 32 || raw_y_count < 1 || raw_y_count > 32 { return -1 }
		x_count := int(raw_x_count)
		y_count := int(raw_y_count)
		if length != usize(x_count + y_count + 2) { return -1 }
		for index in 0 .. x_count + y_count {
			if values[index + 2] < -1_000_000 || values[index + 2] > 1_000_000 { return -1 }
		}
		result_count := x_count + y_count - 1
		byte_count := 8 * result_count
		if unsafe { output == nil } || output_capacity < usize(byte_count) { return -2 }

		y_start := y_count
		for index in 0 .. result_count {
			if index < y_count { y_start -= 1 }
			k_min := if index >= y_count - 1 { index - (y_count - 1) } else { 0 }
			k_max := if index < x_count { index } else { x_count - 1 }
			mut sum := i64(0)
			for k := k_min; k <= k_max; k++ {
				y_index := y_start + (k - k_min)
				sum += values[k + 2] * values[x_count + y_index + 2]
			}
			store_i64_le(mut output, index * 8, sum)
		}
		return i64(byte_count)
	}
}
