module main

const rgb_channel_count = 3
const rgb_hex_output_length = 7

fn hex_digit(value i64) u8 {
	if value < 10 { return u8(48 + value) }
	return u8(87 + value)
}

@[export: 'rgbto_hex']
pub fn rgbto_hex(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if length != rgb_channel_count || input == nil { return -1 }
		for i in 0 .. rgb_channel_count {
			if input[i] < 0 || input[i] > 255 { return -1 }
		}
		if capacity < rgb_hex_output_length || output == nil { return -2 }
		output[0] = u8('#')
		for i in 0 .. rgb_channel_count {
			output[1 + 2 * i] = hex_digit(input[i] >> 4)
			output[2 + 2 * i] = hex_digit(input[i] & 15)
		}
		return i64(rgb_hex_output_length)
	}
}
