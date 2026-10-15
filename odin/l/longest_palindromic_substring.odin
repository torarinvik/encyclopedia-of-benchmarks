package longest_palindromic_substring

import "core:c"

is_ascii_alphanumeric :: proc "contextless" (value: i64) -> bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

// Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
@(export)
longest_palindromic_substring :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 1000 || values == nil do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if !is_ascii_alphanumeric(values[index]) do return -1
	}

	best_start := c.size_t(0)
	best_length := c.size_t(1)
	for center: c.size_t = 0; center < length; center += 1 {
		left := center
		right := center
		for left > 0 && right + 1 < length &&
			values[left - 1] == values[right + 1] {
			left -= 1
			right += 1
		}
		candidate_length := right - left + 1
		if candidate_length > best_length {
			best_start = left
			best_length = candidate_length
		}

		left = center
		right = center + 1
		for right < length && values[left] == values[right] {
			candidate_length = right - left + 1
			if candidate_length > best_length {
				best_start = left
				best_length = candidate_length
			}
			if left == 0 || right + 1 == length do break
			left -= 1
			right += 1
		}
	}

	if output_capacity < best_length || output == nil do return -2
	for index: c.size_t = 0; index < best_length; index += 1 {
		output[index] = u8(values[best_start + index])
	}
	return i64(best_length)
}
