package merge_two_sorted_lists

import "core:c"

MAX_TOTAL_LENGTH :: 1024

// Linear merge over two packed ascending i32 sequences.
@(export)
merge_two_sorted_lists :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_TOTAL_LENGTH + 2) do return -1
	if input[0] < 0 || input[0] > MAX_TOTAL_LENGTH || input[1] < 0 || input[1] > MAX_TOTAL_LENGTH do return -1
	first_count := c.size_t(input[0])
	second_count := c.size_t(input[1])
	if first_count + second_count > MAX_TOTAL_LENGTH || length != first_count + second_count + 2 do return -1
	for index := c.size_t(0); index < first_count; index += 1 {
		value := input[index + 2]
		if value < -2147483648 || value > 2147483647 || (index > 0 && input[index + 1] > value) { return -1 }
	}
	second_start := first_count + 2
	for index := c.size_t(0); index < second_count; index += 1 {
		value := input[second_start + index]
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && input[second_start + index - 1] > value) { return -1 }
	}

	total_count := first_count + second_count
	output_bytes := total_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	first_index := c.size_t(0)
	second_index := c.size_t(0)
	for written := c.size_t(0); written < total_count; written += 1 {
		value: i64
		if first_index == first_count {
			value = input[second_start + second_index]
			second_index += 1
		} else if second_index == second_count {
			value = input[first_index + 2]
			first_index += 1
		} else if input[first_index + 2] <= input[second_start + second_index] {
			value = input[first_index + 2]
			first_index += 1
		} else {
			value = input[second_start + second_index]
			second_index += 1
		}
		bits := u32(i32(value))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
	}
	return i64(total_count)
}
