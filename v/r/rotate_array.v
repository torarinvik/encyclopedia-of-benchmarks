module rotate_array

const max_array_length = 1024
const max_input_length = 1025
const max_rotations = 1024

// Rotate an array right by repeating a one-place shift.
@[export: 'rotate_array']
pub fn rotate_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_length { return -1 }
	rotations := unsafe { input[0] }
	if rotations < 0 || rotations > max_rotations { return -1 }
	count := int(length) - 1
	mut values := [max_array_length]i32{init: 0}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	output_bytes := usize(count * 4)
	if output_capacity < output_bytes { return -2 }
	for _ in 0 .. int(rotations) {
		if count > 1 {
			last := values[count - 1]
			for index := count - 1; index > 0; index-- { values[index] = values[index - 1] }
			values[0] = last
		}
	}
	for index in 0 .. count {
		bits := u32(values[index])
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
	}
	return i64(count)
}
