package longest_palindromic_substring_dp

MAX_LENGTH :: 1000

is_ascii_alphanumeric :: proc "contextless" (value: i64) -> bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

// Find the rightmost longest ASCII alphanumeric palindrome with substring DP.
@(export)
longest_palindromic_substring_dp :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		if !is_ascii_alphanumeric(values[index]) do return -1
	}

	input_length := int(length)
	palindrome := make([]bool, input_length * input_length)
	best_start := 0
	best_end := 0
	for gap := 0; gap < input_length; gap += 1 {
		for start_index := 0; start_index < input_length - gap; start_index += 1 {
			end_index := start_index + gap
			is_palindrome := false
			if gap == 0 {
				is_palindrome = true
			} else if gap == 1 {
				is_palindrome = values[start_index] == values[end_index]
			} else {
				is_palindrome = values[start_index] == values[end_index] &&
					palindrome[(start_index + 1) * input_length + end_index - 1]
			}
			palindrome[start_index * input_length + end_index] = is_palindrome
			if is_palindrome {
				best_start = start_index
				best_end = end_index
			}
		}
	}

	best_length := best_end - best_start + 1
	if output == nil || output_capacity < c.size_t(best_length) {
		delete(palindrome)
		return -2
	}
	for index := 0; index < best_length; index += 1 {
		output[index] = u8(values[best_start + index])
	}
	delete(palindrome)
	return i64(best_length)
}
