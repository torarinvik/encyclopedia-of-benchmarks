module tsvc_s4117_pair_replicated_gather_map

const max_n = 64
const max_input_length = 161

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s4117_pair_replicated_gather_map']
pub fn tsvc_s4117_pair_replicated_gather_map(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		c_length := (n + 1) / 2
		if int(length) != 1 + 2 * n + c_length { return -1 }
		for i in 1 .. int(length) {
			if input[i] < -2 || input[i] > 2 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * n) { return -2 }
		b_offset := 1
		c_offset := 1 + n
		d_offset := c_offset + c_length
		for i in 0 .. n {
			value := input[b_offset + i] + input[c_offset + i / 2] * input[d_offset + i]
			store_i64_le(mut output, 8 * i, value)
		}
		return i64(n)
	}
}
