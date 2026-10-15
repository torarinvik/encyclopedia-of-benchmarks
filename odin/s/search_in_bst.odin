package search_in_bst

import "core:c"

MAX_NODE_COUNT :: 5000
MAX_VALUE :: 10000000

// Follow the unique BST branch until the target node or an empty child.
@(export)
search_in_bst :: proc "contextless" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	count_value, root, target := input[0], input[1], input[2]
	if count_value < 0 || count_value > MAX_NODE_COUNT ||
		int(length) != 3 + 3 * int(count_value) || target < 1 || target > MAX_VALUE { return -1 }
	count := int(count_value)
	if count == 0 do return -1
	if root < 0 || u64(root) >= u64(count) do return -1
	node := root
	for node != -1 {
		if node < 0 || u64(node) >= u64(count) do return -1
		offset := 3 + 3 * int(node)
		value := input[offset]
		left, right := input[offset + 1], input[offset + 2]
		if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(count)) ||
			(right >= 0 && u64(right) >= u64(count)) { return -1 }
		if value == target do return node
		if target < value { node = left } else { node = right }
	}
	return -1
}
