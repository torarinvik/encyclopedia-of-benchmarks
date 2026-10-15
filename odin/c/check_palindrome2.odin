package check_palindrome2

import "core:c"

MAX_LENGTH :: 1024

lower_ascii :: proc "contextless" (value: i64) -> i64 {
	if value >= 65 && value <= 90 do return value + 32
	return value
}

@(export)
check_palindrome2 :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < 32 || values[index] > 126 do return -1
	}
	start := 0
	end := int(length)
	for start < end && values[start] == 32 { start += 1 }
	for end > start && values[end - 1] == 32 { end -= 1 }
	normalized_length := end - start
	if normalized_length == 0 || (normalized_length == 1 && values[start] == 48) do return -1

	palindrome := true
	for left := 0; left < normalized_length / 2; left += 1 {
		right := normalized_length - left - 1
		if lower_ascii(values[start + left]) != lower_ascii(values[start + right]) do palindrome = false
	}
	suffix := " - a palindrome string.\n"
	if !palindrome do suffix = " - not a palindrome string.\n"
	required := c.size_t(normalized_length + len(suffix))
	if output == nil || output_capacity < required do return -2
	for index := 0; index < normalized_length; index += 1 {
		output[index] = u8(lower_ascii(values[start + index]))
	}
	for index := 0; index < len(suffix); index += 1 {
		output[normalized_length + index] = suffix[index]
	}
	return i64(required)
}
