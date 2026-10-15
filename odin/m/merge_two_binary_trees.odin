package merge_two_binary_trees

import "core:c"

MAX_TREE_SLOTS :: 255
MAX_INPUT_LENGTH :: 512
NULL_SLOT :: -1_000_001

valid_tree :: proc "contextless" (input: [^]i64, start, count: c.size_t) -> bool {
	for index := c.size_t(0); index < count; index += 1 {
		value := input[start + index]
		if value != NULL_SLOT && (value < -100_000 || value > 100_000) do return false
		if index > 0 && input[start + (index - 1) / 2] == NULL_SLOT && value != NULL_SLOT do return false
	}
	return true
}

@(export)
merge_two_binary_trees :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 2 || length > MAX_INPUT_LENGTH || input == nil do return -1
	if input[0] < 0 || input[0] > MAX_TREE_SLOTS do return -1
	first_count := c.size_t(input[0])
	second_count_position := first_count + 1
	if second_count_position >= length do return -1
	if input[second_count_position] < 0 || input[second_count_position] > MAX_TREE_SLOTS do return -1
	second_count := c.size_t(input[second_count_position])
	first_start := c.size_t(1)
	second_start := second_count_position + 1
	if length != second_start + second_count do return -1
	if !valid_tree(input, first_start, first_count) || !valid_tree(input, second_start, second_count) do return -1

	maximum_slots := max(first_count, second_count)
	merged: [MAX_TREE_SLOTS]i32
	node_count := i64(0)
	for index := c.size_t(0); index < maximum_slots; index += 1 {
		first := i64(NULL_SLOT)
		second := i64(NULL_SLOT)
		if index < first_count { first = input[first_start + index] }
		if index < second_count { second = input[second_start + index] }
		if first == NULL_SLOT && second == NULL_SLOT {
			merged[index] = i32(NULL_SLOT)
		} else {
			first_value := i64(0)
			second_value := i64(0)
			if first != NULL_SLOT { first_value = first }
			if second != NULL_SLOT { second_value = second }
			merged[index] = i32(first_value + second_value)
			node_count += 1
		}
	}
	output_slots := maximum_slots
	for output_slots > 0 && merged[output_slots - 1] == i32(NULL_SLOT) { output_slots -= 1 }
	output_bytes := output_slots * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	for index := c.size_t(0); index < output_slots; index += 1 {
		bits := u32(merged[index])
		for byte := c.size_t(0); byte < 4; byte += 1 { output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
	return node_count
}
