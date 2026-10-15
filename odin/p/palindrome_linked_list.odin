package palindrome_linked_list

import "core:c"

// Compare the linked-list value sequence from both ends without mutation.
@(export)
palindrome_linked_list :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 100000 do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 0 || values[index] > 9 do return -1
	}

	left := c.size_t(0)
	right := length
	for left < right {
		right -= 1
		if values[left] != values[right] do return 0
		left += 1
	}
	return 1
}
