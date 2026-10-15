module rotate_array_reversal

const max_array_length = 1024
const max_input_length = 1025

fn reverse_range(mut values &i32, start_value int, end_value int) {
	mut start := start_value
	mut ending := end_value
	for start < ending {
		ending--
		if start >= ending { break }
		unsafe {
			temporary := values[start]
			values[start] = values[ending]
			values[ending] = temporary
		}
		start++
	}
}

// Rotate by reversing the whole array, then each side of the rotation.
@[export: 'rotate_array_reversal']
pub fn rotate_array_reversal(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_input_length { return -1 }
	steps := unsafe { input[0] }
	if steps < -2147483648 || steps > 2147483647 { return -1 }
	count := int(length) - 1
	mut values := [max_array_length]i32{init: 0}
	for index in 0 .. count {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		values[index] = i32(value)
	}
	output_bytes := usize(count * 4)
	if output_capacity < output_bytes { return -2 }
	mut shift := 0
	if count > 0 {
		shift = int(steps % i64(count))
		if shift < 0 { shift += count }
	}
	reverse_range(mut values[0], 0, count)
	reverse_range(mut values[0], 0, shift)
	reverse_range(mut values[0], shift, count)
	for index in 0 .. count {
		bits := u32(values[index])
		for byte in 0 .. 4 {
			unsafe { output[index * 4 + byte] = u8((bits >> (byte * 8)) & 255) }
		}
	}
	return i64(count)
}
