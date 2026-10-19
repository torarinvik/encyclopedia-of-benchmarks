module stream_vector_kernels

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'stream_vector_kernels']
pub fn stream_vector_kernels(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 259 { return -1 }
	unsafe {
		mode := input[0]
		count_value := input[1]
		if mode < 0 || mode > 3 || count_value < 0 || count_value > 128 { return -1 }
		count := int(count_value)
		has_alpha := mode == 1 || mode == 3
		array_count := if mode == 0 || mode == 1 { 1 } else { 2 }
		expected_length := 2 + (if has_alpha { 1 } else { 0 }) + array_count * count
		if int(length) != expected_length { return -1 }

		mut a_start := 2
		mut alpha := i64(0)
		if has_alpha {
			alpha = input[2]
			if alpha < -1000 || alpha > 1000 { return -1 }
			a_start = 3
		}
		b_start := a_start + count
		for index in 0 .. array_count * count {
			value := input[a_start + index]
			if value < -1000 || value > 1000 { return -1 }
		}

		mut staged := []i64{len: 128, init: 0}
		for index in 0 .. count {
			a := input[a_start + index]
			value := match mode {
				0 { a }
				1 { alpha * a }
				2 { a + input[b_start + index] }
				else { a + alpha * input[b_start + index] }
			}
			staged[index] = value
		}

		output_bytes := count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. count {
			write_i64_le(mut output, index * 8, staged[index])
		}
		return i64(output_bytes)
	}
}
