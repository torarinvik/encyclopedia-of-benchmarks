module random

const max_count = 256
const max_input_length = 5
const max_output_bytes = max_count * 4

fn write_u32_le(mut output &u8, index int, value u32) {
	unsafe {
		offset := index * 4
		for byte in 0 .. 4 {
			output[offset + byte] = u8(value >> u32(byte * 8))
		}
	}
}

fn rotate_right(value u32, rotation u32) u32 {
	left_shift := (u32(32) - rotation) & u32(31)
	return (value >> rotation) | (value << left_shift)
}

@[export: 'pcg32_random']
pub fn pcg32_random(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 4 || length > max_input_length { return -1 }
		if length != 4 { return -1 }

		seed := u64(values[0])
		multiplier := u64(values[1])
		stream_value, count_value := values[2], values[3]
		if stream_value < 0 || count_value < 0 || count_value > max_count { return -1 }

		stream := u64(stream_value)
		increment := (stream << 1) | u64(1)
		mut state := seed +% increment
		state = state *% multiplier +% increment
		count := int(count_value)
		required_bytes := count * 4
		if required_bytes > max_output_bytes { return -1 }
		if output == nil || output_capacity < usize(required_bytes) { return -2 }

		for index in 0 .. count {
			mut value := state
			rotation := u32(value >> 59)
			state = state *% multiplier +% increment
			value ^= value >> 18
			xorshifted := u32(value >> 27)
			write_u32_le(mut output, index, rotate_right(xorshifted, rotation))
		}
		return i64(required_bytes)
	}
}
