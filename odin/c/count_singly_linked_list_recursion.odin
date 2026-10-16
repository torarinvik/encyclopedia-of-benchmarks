package count_singly_linked_list_recursion

import "core:c"

MAX_NODES :: 64
MIN_PAYLOAD :: -2147483648
MAX_PAYLOAD :: 2147483647

count_recursive :: proc(input: [^]i64, index, remaining: int) -> i64 {
	if remaining == 0 do return 0
	payload := input[index]
	if payload < MIN_PAYLOAD || payload > MAX_PAYLOAD do return -1
	tail_count := count_recursive(input, index + 1, remaining - 1)
	if tail_count < 0 do return -1
	return 1 + tail_count
}

// Recursively count a finite singly linked chain represented in node order.
@(export)
count_singly_linked_list_recursion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 0 || input[0] > MAX_NODES do return -1
	count := int(input[0])
	if length != c.size_t(count + 1) do return -1
	return count_recursive(input, 1, count)
}
