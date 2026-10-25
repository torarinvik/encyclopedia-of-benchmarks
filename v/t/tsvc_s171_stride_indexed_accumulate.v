module tsvc_s171_stride_indexed_accumulate

const max_n = 32
const max_stride = 4
const max_input_length = 159

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s171_stride_indexed_accumulate']
pub fn tsvc_s171_stride_indexed_accumulate(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_stride { return -1 }
		n := int(input[0])
		stride := int(input[1])
		a_length := 1 + (n - 1) * stride
		if int(length) != 2 + a_length + n { return -1 }
		for i in 0 .. a_length + n {
			if input[2 + i] < -8 || input[2 + i] > 8 { return -1 }
		}
		if unsafe { output == nil } || capacity < usize(8 * a_length) { return -2 }
		for i in 0 .. a_length {
			store_i64_le(mut output, 8 * i, input[2 + i])
		}
		b_offset := 2 + a_length
		for i in 0 .. n {
			destination := i * stride
			store_i64_le(mut output, 8 * destination, input[2 + destination] + input[b_offset + i])
		}
		return i64(a_length)
	}
}
