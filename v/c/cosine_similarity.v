module cosine_similarity

import math

const max_string_length = 64
const max_input_length = 132
const alphabet_size = 95
const invalid_result = -1.0e300

@[export: 'cosine_similarity']
pub fn cosine_similarity(input &i64, length usize) f64 {
	if input == nil || length < 2 || length > max_input_length { return invalid_result }
	unsafe {
		left_length_value := input[0]
		right_length_value := input[1]
		if left_length_value < 0 || left_length_value > max_string_length
			|| right_length_value < 0 || right_length_value > max_string_length { return invalid_result }
		left_length := int(left_length_value)
		right_length := int(right_length_value)
		if length != usize(2 + left_length + right_length) { return invalid_result }

		mut left_counts := [alphabet_size]u64{}
		mut right_counts := [alphabet_size]u64{}
		for index in 0 .. left_length {
			mut value := input[2 + index]
			if value < 32 || value > 126 { return invalid_result }
			if value >= 65 && value <= 90 { value += 32 }
			left_counts[int(value - 32)]++
		}
		for index in 0 .. right_length {
			mut value := input[2 + left_length + index]
			if value < 32 || value > 126 { return invalid_result }
			if value >= 65 && value <= 90 { value += 32 }
			right_counts[int(value - 32)]++
		}

		mut dot_product := 0.0
		mut left_magnitude_squared := 0.0
		mut right_magnitude_squared := 0.0
		for index in 0 .. alphabet_size {
			left := f64(left_counts[index])
			right := f64(right_counts[index])
			dot_product += left * right
			left_magnitude_squared += left * left
			right_magnitude_squared += right * right
		}
		if left_magnitude_squared <= 0.0 || right_magnitude_squared <= 0.0 { return 0.0 }
		return dot_product / (math.sqrt(left_magnitude_squared) * math.sqrt(right_magnitude_squared))
	}
}
