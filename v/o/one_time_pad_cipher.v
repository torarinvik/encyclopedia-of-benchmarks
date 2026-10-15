module one_time_pad_cipher

const max_text_length = 1024

@[export: 'one_time_pad_cipher']
pub fn one_time_pad_cipher(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > 2 + 2 * max_text_length { return -1 }
	mode := unsafe { input[0] }
	count_value := unsafe { input[1] }
	if (mode != 0 && mode != 1) || count_value < 0 || count_value > max_text_length { return -1 }
	count := int(count_value)
	if int(length) != 2 + 2 * count { return -1 }
	if output_capacity < usize(count) { return -2 }
	for index in 0 .. count {
		data := unsafe { input[2 + index] }
		key := unsafe { input[2 + count + index] }
		if data < 0 || data > 255 || key < 0 || key > 255 { return -1 }
		unsafe { output[index] = u8(data ^ key) }
	}
	return i64(count)
}
