module length

const max_payload_bytes = 256
const max_input_length = 259
const output_bytes = 16

fn utf8_scalar_count(bytes &u8, payload_length int) i64 {
	mut index := 0
	mut count := i64(0)
	for index < payload_length {
		lead := unsafe { bytes[index] }
		if lead >= 1 && lead <= 0x7f {
			index++
		} else if lead >= 0xc2 && lead <= 0xdf {
			if index + 1 >= payload_length { return -1 }
			second := unsafe { bytes[index + 1] }
			if second < 0x80 || second > 0xbf { return -1 }
			index += 2
		} else if lead >= 0xe0 && lead <= 0xef {
			if index + 2 >= payload_length { return -1 }
			second := unsafe { bytes[index + 1] }
			third := unsafe { bytes[index + 2] }
			if second < 0x80 || second > 0xbf || third < 0x80 || third > 0xbf ||
				(lead == 0xe0 && second < 0xa0) || (lead == 0xed && second > 0x9f) {
				return -1
			}
			index += 3
		} else {
			return -1
		}
		count++
	}
	return count
}

fn put_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'length']
pub fn length(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_payload_bytes { return -1 }
		payload_length := int(input[0])
		if input_length != usize(payload_length + 2) { return -1 }

		mut payload := [max_payload_bytes]u8{}
		for index := 0; index <= payload_length; index++ {
			value := input[index + 1]
			if value < 0 || value > 255 { return -1 }
			if index == payload_length {
				if value != 0 { return -1 }
			} else {
				if value == 0 { return -1 }
				payload[index] = u8(value)
			}
		}
		scalar_count := utf8_scalar_count(&payload[0], payload_length)
		if scalar_count < 0 { return -1 }
		if output == nil || output_capacity < output_bytes { return -2 }

		put_i64_le(output, 0, i64(payload_length))
		put_i64_le(output, 8, scalar_count)
		return output_bytes
	}
}
