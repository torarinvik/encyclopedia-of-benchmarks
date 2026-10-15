package middle_of_linked_list

import "core:c"

MAX_NODES :: 100000

@(export)
middle_of_linked_list :: proc "contextless" (next: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_NODES || (length != 0 && next == nil) do return -2
	for index := c.size_t(0); index < length; index += 1 {
		if next[index] < -1 || next[index] >= i64(length) do return -2
	}
	if length == 0 do return -1

	slow := i64(0)
	fast := i64(0)
	for fast >= 0 {
		first := next[fast]
		if first < 0 do break
		slow = next[slow]
		fast = next[first]
		if slow == fast do return -2
	}

	slow = 0
	fast = 0
	for fast >= 0 {
		first := next[fast]
		if first < 0 do break
		slow = next[slow]
		fast = next[first]
	}
	return slow
}
