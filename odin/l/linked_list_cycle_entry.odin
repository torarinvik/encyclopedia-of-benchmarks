package linked_list_cycle_entry

import "core:c"

MAX_NODES :: 100000

valid_successors :: proc "contextless" (next: [^]i64, length: c.size_t) -> bool {
	if length > c.size_t(MAX_NODES) || (length != 0 && next == nil) do return false
	for index := c.size_t(0); index < length; index += 1 {
		if next[index] < -1 || next[index] >= i64(length) do return false
	}
	return true
}

successor :: proc "contextless" (next: [^]i64, node: i64) -> i64 {
	if node < 0 do return -1
	return next[int(node)]
}

// Returns the cycle-entry node index, -1 when acyclic, and -2 for malformed input.
@(export)
linked_list_cycle_entry :: proc "c" (next: [^]i64, length: c.size_t) -> i64 {
	if !valid_successors(next, length) do return -2
	if length == 0 do return -1
	slow, fast: i64 = 0, 0
	meeting := false
	for fast >= 0 {
		first := successor(next, fast)
		if first < 0 do break
		slow = successor(next, slow)
		fast = successor(next, first)
		if slow == fast { meeting = true; break }
	}
	if !meeting do return -1
	entry: i64 = 0
	for entry != slow {
		entry = successor(next, entry)
		slow = successor(next, slow)
	}
	return entry
}
