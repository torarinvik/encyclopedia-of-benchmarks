module intersection_of_two_linked_lists

const max_list_length = 1024
const max_input_length = 2050

// Find the first shared node identity by switching traversal heads.
@[export: 'intersection_of_two_linked_lists']
pub fn intersection_of_two_linked_lists(input &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return -2 }
	first_length_value := unsafe { input[0] }
	second_length_value := unsafe { input[1] }
	if first_length_value < 0 || first_length_value > max_list_length || second_length_value < 0 || second_length_value > max_list_length { return -2 }
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length { return -2 }
	for index in 2 .. int(length) {
		value := unsafe { input[index] }
		if value < 0 || value > 2147483647 { return -2 }
	}
	if first_length == 0 || second_length == 0 { return -1 }

	mut first_position := 0
	mut second_position := 0
	mut first_on_first_list := true
	mut second_on_first_list := false
	for _ in 0 .. first_length + second_length + 1 {
		first_base := if first_on_first_list { 2 } else { 2 + first_length }
		first_source_length := if first_on_first_list { first_length } else { second_length }
		second_base := if second_on_first_list { 2 } else { 2 + first_length }
		second_source_length := if second_on_first_list { first_length } else { second_length }
		first_node := unsafe { input[first_base + first_position] }
		second_node := unsafe { input[second_base + second_position] }
		if first_node == second_node { return first_node }
		first_position++
		second_position++
		first_is_null := first_position == first_source_length
		second_is_null := second_position == second_source_length
		if first_is_null && second_is_null { return -1 }
		if first_is_null { first_on_first_list = !first_on_first_list; first_position = 0 }
		if second_is_null { second_on_first_list = !second_on_first_list; second_position = 0 }
	}
	return -1
}
