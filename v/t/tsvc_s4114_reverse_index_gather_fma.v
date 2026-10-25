module tsvc_s4114_reverse_index_gather_fma

const max_n = 64
const max_input_length = 257

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s4114_reverse_index_gather_fma']
pub fn tsvc_s4114_reverse_index_gather_fma(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if int(length) != 1 + 4 * n { return -1 }
		ip_offset := 1
		b_offset := 1 + n
		c_offset := 1 + 2 * n
		d_offset := 1 + 3 * n
		for i in 0 .. n {
			if input[ip_offset + i] < 0 || input[ip_offset + i] >= i64(n) { return -1 }
			if input[b_offset + i] < -2 || input[b_offset + i] > 2 ||
				input[c_offset + i] < -2 || input[c_offset + i] > 2 ||
				input[d_offset + i] < -2 || input[d_offset + i] > 2 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }
		for i in 0 .. n {
			gathered := n - 1 - int(input[ip_offset + i])
			value := input[b_offset + i] + input[c_offset + gathered] * input[d_offset + i]
			store_i64_le(mut output, 8 * i, value)
		}
		return i64(n)
	}
}
