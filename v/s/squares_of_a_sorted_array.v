module squares_of_a_sorted_array

const max_array_length = 10000

// Square a sorted array and emit the results in ascending order.
@[export: 'squares_of_a_sorted_array']
pub fn squares_of_a_sorted_array(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_array_length { return -1 }
	for index in 0 .. int(length) {
		value := unsafe { input[index] }
		if value < -10000 || value > 10000 { return -1 }
		if index > 0 && unsafe { input[index - 1] > value } { return -1 }
	}
	output_bytes := int(length) * 8
	if output_capacity < usize(output_bytes) { return -2 }

	mut left := 0
	mut right := int(length)
	mut destination := int(length)
	for destination > 0 {
		destination--
		left_value := unsafe { input[left] }
		right_value := unsafe { input[right - 1] }
		left_magnitude := if left_value < 0 { -left_value } else { left_value }
		right_magnitude := if right_value < 0 { -right_value } else { right_value }
		mut value := i64(0)
		if left_magnitude > right_magnitude {
			value = left_value
			left++
		} else {
			value = right_value
			right--
		}
		square := u64(value * value)
		for byte in 0 .. 8 {
			unsafe { output[destination * 8 + byte] = u8((square >> (byte * 8)) & 255) }
		}
	}
	return i64(length)
}
