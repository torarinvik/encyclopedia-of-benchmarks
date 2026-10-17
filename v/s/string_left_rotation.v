module string_left_rotation

const max_string_length = 256
const max_parseable_input_length = 259

@[export: 'string_left_rotation']
pub fn string_left_rotation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		raw_length := input[0]
		raw_rotation := input[1]
		if raw_length < 0 || raw_length > max_string_length || raw_rotation < 0 || raw_rotation > raw_length { return -1 }
		text_length := int(raw_length)
		if length != usize(text_length + 2) { return -1 }
		mut units := [max_string_length]u16{}
		for i in 0 .. text_length {
			if input[i + 2] < 0 || input[i + 2] > 65535 { return -1 }
			units[i] = u16(input[i + 2])
		}
		required := text_length * 2
		if required == 0 { return 0 }
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		rotation := int(raw_rotation)
		for i in 0 .. text_length {
			source := rotation + i
			if source >= text_length { source -= text_length }
			value := units[source]
			output[2 * i] = u8(value & 0xff)
			output[2 * i + 1] = u8(value >> 8)
		}
		return i64(required)
	}
}
