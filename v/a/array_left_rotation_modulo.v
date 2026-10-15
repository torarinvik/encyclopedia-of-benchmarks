module array_left_rotation_modulo

const max_array_length = 1024
const max_input_length = 1025

fn write_i32_le(output &u8, index int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

// Return a fresh left rotation; nonpositive shifts keep order and positive shifts wrap.
@[export: 'array_left_rotation_modulo']
pub fn array_left_rotation_modulo(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_length { return -1 }
	rotations := unsafe { input[0] }
	if rotations < -2147483648 || rotations > 2147483647 { return -1 }
	count := int(length) - 1
	mut values := [max_array_length]i32{init: 0}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	if count == 0 { return 0 }
	shift := if rotations > 0 { int(rotations % i64(count)) } else { 0 }
	output_bytes := usize(count * 4)
	if output_capacity < output_bytes { return -2 }
	for index := shift; index < count; index++ {
		write_i32_le(output, index - shift, values[index])
	}
	for index in 0 .. shift {
		write_i32_le(output, count - shift + index, values[index])
	}
	return i64(count)
}

