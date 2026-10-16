module count_singly_linked_list_recursion

fn count_recursive_input(input &i64, index int, remaining int) i64 {
	if remaining == 0 { return 0 }
	unsafe {
		payload := input[index]
		if payload < -2147483648 || payload > 2147483647 { return -1 }
	}
	tail_count := count_recursive_input(input, index + 1, remaining - 1)
	if tail_count < 0 { return -1 }
	return 1 + tail_count
}

// Recursively count a finite singly linked chain represented in node order.
@[export: 'count_singly_linked_list_recursion']
pub fn count_singly_linked_list_recursion(input &i64, length usize) i64 {
	if length < 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 64 { return -1 }
		count := int(input[0])
		if int(length) != count + 1 { return -1 }
		return count_recursive_input(input, 1, count)
	}
}
