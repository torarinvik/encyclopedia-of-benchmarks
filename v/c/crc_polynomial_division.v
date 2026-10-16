module crc_polynomial_division

@[export: 'crc_polynomial_division']
pub fn crc_polynomial_division(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > 3 + 79 + 16 { return -1 }
	operation := unsafe { input[0] }
	raw_message_length := unsafe { input[1] }
	raw_polynomial_length := unsafe { input[2] }
	if operation < 0 || operation > 1 || raw_message_length < 1
		|| (operation == 0 && raw_message_length > 64)
		|| (operation == 1 && raw_message_length > 79) || raw_polynomial_length < 2
		|| raw_polynomial_length > 16 {
		return -1
	}
	message_length, polynomial_length := int(raw_message_length), int(raw_polynomial_length)
	if length != usize(3 + message_length + polynomial_length) { return -1 }

	mut polynomial := u32(0)
	for index in 0 .. polynomial_length {
		bit := unsafe { input[3 + message_length + index] }
		if bit < 0 || bit > 1 { return -1 }
		if index == 0 || index == polynomial_length - 1 {
			if bit != 1 { return -1 }
		}
		polynomial = (polynomial << 1) | u32(bit)
	}

	degree := polynomial_length - 1
	leading_mask := u32(1) << degree
	mut remainder := u32(0)
	for index in 0 .. message_length {
		bit := unsafe { input[3 + index] }
		if bit < 0 || bit > 1 { return -1 }
		remainder = (remainder << 1) | u32(bit)
		if remainder & leading_mask != 0 { remainder ^= polynomial }
	}
	if operation == 0 {
		for _ in 0 .. degree {
			remainder <<= 1
			if remainder & leading_mask != 0 { remainder ^= polynomial }
		}
	}

	if operation == 1 {
		if unsafe { output == nil } || capacity < 1 { return -2 }
		unsafe {
			if remainder == 0 {
				output[0] = 0
			} else {
				output[0] = 1
			}
		}
		return 1
	}

	output_length := message_length + degree
	if unsafe { output == nil } || capacity < usize(output_length) { return -2 }
	for index in 0 .. message_length {
		bit := unsafe { input[3 + index] }
		unsafe {
			output[index] = u8(bit)
		}
	}
	for index in 0 .. degree {
		shift := degree - 1 - index
		bit := u8((remainder >> shift) & 1)
		unsafe {
			output[message_length + index] = bit
		}
	}
	return i64(output_length)
}
