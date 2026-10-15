module base85

const max_input_values = 66
const max_decoded_length = 52

fn decode_group(values &i64, start usize, count usize) i64 {
	mut value := u64(0)
	for index := 0; index < 5; index++ {
		mut digit := u64(84)
		if usize(index) < count {
			byte := unsafe { values[start + usize(index)] }
			if byte < 33 || byte > 117 { return -1 }
			digit = u64(byte - 33)
		}
		value = value * 85 + digit
	}
	if value > 4294967295 { return -1 }
	return i64(value)
}

@[export: 'base85']
pub fn base85(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length == 0 || length > max_input_values { return -1 }
	mode := unsafe { values[0] }
	payload_length := length - 1
	mut output_length := usize(0)
	if mode == 0 {
		for index := usize(1); index < length; index++ {
			byte := unsafe { values[index] }
			if byte < 0 || byte > 255 { return -1 }
		}
		remainder := payload_length % 4
		output_length = (payload_length / 4) * 5
		if remainder != 0 { output_length += remainder + 1 }
	} else if mode == 1 {
		if payload_length % 5 == 1 { return -1 }
		mut offset := usize(0)
		for offset < payload_length {
			count := if payload_length - offset < 5 { payload_length - offset } else { usize(5) }
			if decode_group(values, offset + 1, count) < 0 { return -1 }
			if count == 5 { output_length += 4 } else { output_length += count - 1 }
			offset += count
		}
		if output_length > max_decoded_length { return -1 }
	} else {
		return -1
	}
	if output_capacity < output_length { return -2 }

	mut written := usize(0)
	if mode == 0 {
		mut offset := usize(0)
		for offset < payload_length {
			count := if payload_length - offset < 4 { payload_length - offset } else { usize(4) }
			mut value := u64(0)
			for byte := usize(0); byte < 4; byte++ {
				value <<= 8
				if byte < count { value |= u64(unsafe { values[offset + byte + 1] }) }
			}
			mut place := u64(52200625)
			for digit := usize(0); digit < 5; digit++ {
				encoded := u8(value / place + 33)
				value %= place
				if count == 4 || digit < count + 1 {
					unsafe { output[written] = encoded }
					written++
				}
				if digit == 0 { place = 614125 }
				else if digit == 1 { place = 7225 }
				else if digit == 2 { place = 85 }
				else { place = 1 }
			}
			offset += 4
		}
	} else {
		mut offset := usize(0)
		for offset < payload_length {
			count := if payload_length - offset < 5 { payload_length - offset } else { usize(5) }
			value := u64(decode_group(values, offset + 1, count))
			byte_count := if count == 5 { usize(4) } else { count - 1 }
			for byte := usize(0); byte < byte_count; byte++ {
				unsafe { output[written] = u8((value >> (24 - 8 * byte)) & 255) }
				written++
			}
			offset += count
		}
	}
	return i64(written)
}
