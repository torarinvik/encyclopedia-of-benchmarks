module iso10126_d2_padding

const max_buffer_length = 64
const max_input_values = 66

@[export: 'iso10126_d2_padding']
pub fn iso10126_d2_padding(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_values { return -1 }
		mode := input[0]
		if mode == 0 {
			if length < 3 { return -1 }
			offset := input[1]
			buffer_length := input[2]
			if buffer_length < 1 || buffer_length > max_buffer_length || offset < 0 || offset >= buffer_length { return -1 }
			if length != usize(3 + offset + buffer_length - offset - 1) { return -1 }
			for i in 3 .. int(length) {
				if input[i] < 0 || input[i] > 255 { return -1 }
			}
			for i in 3 + int(offset) .. int(length) {
				if input[i] >= 255 { return -1 }
			}
			output_bytes := usize(buffer_length + 1)
			if output == nil || capacity < output_bytes { return -2 }
			padding_count := u8(buffer_length - offset)
			output[0] = padding_count
			mut position := 1
			for i in 0 .. int(offset) {
				output[position] = u8(input[3 + i])
				position++
			}
			for i in 3 + int(offset) .. int(length) {
				output[position] = u8(input[i])
				position++
			}
			output[position] = padding_count
			return i64(output_bytes)
		}
		if (mode != 1 && mode != 2) || length < 3 { return -1 }
		buffer_length := input[1]
		if buffer_length < 1 || buffer_length > max_buffer_length || length != usize(2 + buffer_length) { return -1 }
		for i in 2 .. int(length) {
			if input[i] < 0 || input[i] > 255 { return -1 }
		}
		padding_count := input[length - 1]
		if padding_count < 1 || padding_count > buffer_length { return -1 }
		output_bytes := if mode == 1 { usize(buffer_length - padding_count) } else { usize(1) }
		if output == nil || capacity < output_bytes { return -2 }
		if mode == 1 {
			for i in 0 .. int(output_bytes) { output[i] = u8(input[2 + i]) }
		} else {
			output[0] = u8(padding_count)
		}
		return i64(output_bytes)
	}
}
