module tsvc_s315_maximum_with_index

const max_n = 64
const max_input_length = 1 + max_n
const max_value = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s315_maximum_with_index']
pub fn tsvc_s315_maximum_with_index(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	if int(length) != 1 + n { return -1 }
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < -max_value || value > max_value { return -1 }
	}
	if unsafe { output == nil } || output_capacity < 16 { return -2 }

	mut maximum := unsafe { input[1] }
	mut maximum_index := 0
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value > maximum {
			maximum = value
			maximum_index = i
		}
	}
	store_i64_le(mut output, 0, maximum)
	store_i64_le(mut output, 8, i64(maximum_index))
	return 2
}
