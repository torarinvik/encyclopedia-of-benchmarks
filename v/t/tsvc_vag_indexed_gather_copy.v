module tsvc_vag_indexed_gather_copy

const max_n = 64
const max_input_length = 1 + 2 * max_n
const max_value = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_vag_indexed_gather_copy']
pub fn tsvc_vag_indexed_gather_copy(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + 2 * n { return -1 }
	for i in 0 .. n {
		index := unsafe { input[1 + i] }
		value := unsafe { input[1 + n + i] }
		if index < 0 || index >= n_raw { return -1 }
		if value < -max_value || value > max_value { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * n) { return -2 }

	for i in 0 .. n {
		index := int(unsafe { input[1 + i] })
		store_i64_le(mut output, 8 * i, unsafe { input[1 + n + index] })
	}
	return i64(n)
}
