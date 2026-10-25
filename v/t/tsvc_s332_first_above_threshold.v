module tsvc_s332_first_above_threshold

const max_n = 256
const max_input_length = 258

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'tsvc_s332_first_above_threshold']
pub fn tsvc_s332_first_above_threshold(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_n || input[1] < -1000000 || input[1] > 1000000 { return -1 }
		n := int(input[0])
		threshold := input[1]
		if int(length) != 2 + n { return -1 }
		mut values := [max_n]i64{}
		for i in 0 .. n {
			values[i] = input[2 + i]
			if values[i] < -1000000 || values[i] > 1000000 { return -1 }
		}
		if unsafe { output == nil } || capacity < 16 { return -2 }
		mut index := i64(-2)
		mut value := i64(-1)
		for i in 0 .. n {
			if values[i] > threshold {
				index = i64(i)
				value = values[i]
				break
			}
		}
		store_i64_le(mut output, 0, index)
		store_i64_le(mut output, 8, value)
		return 2
	}
}
