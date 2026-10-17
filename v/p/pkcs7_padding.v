module pkcs7_padding

@[export: 'pkcs7_padding']
pub fn pkcs7_padding(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > 69 { return -1 }
	operation := unsafe { input[0] }
	block_arg := unsafe { input[1] }
	offset_arg := unsafe { input[2] }
	data_arg := unsafe { input[3] }
	if operation < 0 || operation > 2 || block_arg < 1 || block_arg > 16 ||
		data_arg < 1 || data_arg > 64 ||
		(operation == 0 && (offset_arg < 0 || offset_arg > data_arg)) ||
		length != usize(data_arg) + 4 { return -1 }
	block_size := usize(block_arg)
	offset := if operation == 0 { usize(offset_arg) } else { usize(0) }
	data_length := usize(data_arg)
	for index := usize(0); index < data_length; index++ {
		value := unsafe { input[index + 4] }
		if value < 0 || value > 255 { return -1 }
	}

	mut padding_count := usize(0)
	mut output_length := usize(0)
	if operation == 0 {
		padding_count = block_size - data_length % block_size
		if offset + padding_count > data_length { return -1 }
		output_length = data_length + 1
	} else if operation == 1 {
		if data_length % block_size != 0 { return -1 }
		padding_count = usize(unsafe { input[data_length + 3] })
		if padding_count == 0 || padding_count > block_size { return -1 }
		for index := data_length - padding_count; index < data_length; index++ {
			if usize(unsafe { input[index + 4] }) != padding_count { return -1 }
		}
		output_length = data_length - padding_count
	} else {
		padding_count = usize(unsafe { input[data_length + 3] })
		padding_start := i64(data_length) - i64(padding_count)
		invalid_bits := padding_start | (i64(padding_count) - 1)
		mut padding_check_failed := -i64(u32(invalid_bits) >> 31)
		for index := usize(0); index < data_length; index++ {
			difference := i64(index) - padding_start
			negative_bit := u32(difference) >> 31
			mask := -i64(1 - negative_bit)
			value := unsafe { input[index + 4] }
			padding_check_failed |= (value ^ i64(padding_count)) & mask
		}
		if padding_check_failed != 0 { return -1 }
		output_length = 1
	}
	if unsafe { output == nil } || output_capacity < output_length { return -2 }
	if operation == 0 {
		unsafe { output[0] = u8(padding_count) }
		for index := usize(0); index < data_length; index++ {
			value := unsafe { input[index + 4] }
			if index >= offset && index < offset + padding_count { value = i64(padding_count) }
			unsafe { output[index + 1] = u8(value) }
		}
	} else if operation == 1 {
		for index := usize(0); index < output_length; index++ {
			unsafe { output[index] = u8(input[index + 4]) }
		}
	} else {
		unsafe { output[0] = u8(padding_count) }
	}
	return i64(output_length)
}
