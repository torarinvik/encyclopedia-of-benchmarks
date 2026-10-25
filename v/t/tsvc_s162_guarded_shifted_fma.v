module tsvc_s162_guarded_shifted_fma

const max_n = 64
const max_input_length = 194

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s162_guarded_shifted_fma']
pub fn tsvc_s162_guarded_shifted_fma(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > 1 { return -1 }
		n := int(input[0])
		if int(length) != 2 + 3 * n { return -1 }
		for i in 2 .. int(length) {
			if input[i] < -2 || input[i] > 2 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }
		a_offset := 2
		b_offset := a_offset + n
		c_offset := b_offset + n
		for i in 0 .. n {
			store_i64_le(mut output, 8 * i, input[a_offset + i])
		}
		if input[1] > 0 {
			for i in 0 .. n - 1 {
				value := input[a_offset + i + 1] + input[b_offset + i] * input[c_offset + i]
				store_i64_le(mut output, 8 * i, value)
			}
		}
		return i64(n)
	}
}
