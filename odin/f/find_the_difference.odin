package find_the_difference

import "core:c"

MAX_STRING_LENGTH :: 4096
MAX_PACKED_LENGTH :: 8195

// Return the lowercase byte added to t by subtracting the two character sums.
@(export)
find_the_difference :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PACKED_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_STRING_LENGTH || input[1] < 1 || input[1] > MAX_STRING_LENGTH + 1 do return -1
	s_length := c.size_t(input[0])
	t_length := c.size_t(input[1])
	if t_length != s_length + 1 || length != 2 + s_length + t_length do return -1
	sum_s := i64(0)
	sum_t := i64(0)
	for index := c.size_t(0); index < s_length; index += 1 {
		value := input[2 + index]
		if value < 97 || value > 122 do return -1
		sum_s += value
	}
	t_start := 2 + s_length
	for index := c.size_t(0); index < t_length; index += 1 {
		value := input[t_start + index]
		if value < 97 || value > 122 do return -1
		sum_t += value
	}
	difference := sum_t - sum_s
	if difference < 97 || difference > 122 do return -1
	return difference
}
