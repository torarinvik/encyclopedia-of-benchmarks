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
		if text_length == 0 { return 0 }
		mut units := [max_string_length]u16{}
		mut observed_bits := u64(0)
		for i in 0 .. text_length {
			value := u64(input[i + 2])
			observed_bits |= value
			units[i] = u16(value)
		}
		if observed_bits > 65535 { return -1 }
		required := text_length * 2
		if output == nil || capacity < usize(required) { return -2 }
		rotation := int(raw_rotation)
		for source in rotation .. text_length {
			destination := 2 * (source - rotation)
			value := units[source]
			output[destination] = u8(value)
			output[destination + 1] = u8(value >> 8)
		}
		suffix_bytes := 2 * (text_length - rotation)
		for source in 0 .. rotation {
			destination := suffix_bytes + 2 * source
			value := units[source]
			output[destination] = u8(value)
			output[destination + 1] = u8(value >> 8)
		}
		return i64(required)
	}
}
