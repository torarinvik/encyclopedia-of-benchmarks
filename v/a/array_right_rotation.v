module array_right_rotation

const max_array_length = 1024
const max_input_length = 1025
const max_shift = 1024

fn write_i32_le(output &u8, index int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

// Return a fresh right rotation; a shift at least as large as the input size yields empty output.
@[export: 'array_right_rotation']
pub fn array_right_rotation(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_length { return -1 }
	shift_value := unsafe { input[0] }
	if shift_value < 0 || shift_value > max_shift { return -1 }
	count := int(length) - 1
	mut values := [max_array_length]i32{init: 0}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	shift := int(shift_value)
	if shift >= count { return 0 }
	output_bytes := usize(count * 4)
	if output_capacity < output_bytes { return -2 }
	for index in 0 .. shift {
		write_i32_le(output, index, values[count - shift + index])
	}
	for index := shift; index < count; index++ {
		write_i32_le(output, index, values[index - shift])
	}
	return i64(count)
}
