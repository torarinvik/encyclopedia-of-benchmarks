package intersection_of_two_linked_lists

import "core:c"

MAX_LIST_LENGTH :: 1024
MAX_INPUT_LENGTH :: 2050

// Find the first shared node identity by switching traversal heads.
@(export)
intersection_of_two_linked_lists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > MAX_INPUT_LENGTH do return -2
	first_length_value := input[0]
	second_length_value := input[1]
	if first_length_value < 0 || first_length_value > MAX_LIST_LENGTH || second_length_value < 0 || second_length_value > MAX_LIST_LENGTH do return -2
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length do return -2
	for index := 2; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 2147483647 do return -2
	}
	if first_length == 0 || second_length == 0 do return -1

	first_position := 0
	second_position := 0
	first_on_first_list := true
	second_on_first_list := false
	for _ in 0 ..< first_length + second_length + 1 {
		first_base := 2
		first_source_length := first_length
		if !first_on_first_list { first_base = 2 + first_length; first_source_length = second_length }
		second_base := 2 + first_length
		second_source_length := second_length
		if second_on_first_list { second_base = 2; second_source_length = first_length }
		first_node := input[first_base + first_position]
		second_node := input[second_base + second_position]
		if first_node == second_node do return first_node
		first_position += 1
		second_position += 1
		first_is_null := first_position == first_source_length
		second_is_null := second_position == second_source_length
		if first_is_null && second_is_null do return -1
		if first_is_null { first_on_first_list = !first_on_first_list; first_position = 0 }
		if second_is_null { second_on_first_list = !second_on_first_list; second_position = 0 }
	}
	return -1
}
