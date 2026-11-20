package union_find_enumerate

import "core:c"

MAX_ITEMS :: 16
MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 99

find_root :: proc "contextless" (parent: [^]i64, item: int) -> int {
	root := item
	for parent[root] >= 0 { root = int(parent[root]) }
	current := item
	for current != root {
		next_item := int(parent[current])
		parent[current] = i64(root)
		current = next_item
	}
	return root
}

component_mask :: proc "contextless" (successor: [^]i64, start: int) -> i64 {
	mask: u64 = 0
	item := start
	for {
		mask |= u64(1) << u64(item)
		item = int(successor[item])
		if item == start { break }
	}
	return i64(mask)
}

@(export)
union_find_enumerate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	item_count_value, operation_count_value := input[0], input[1]
	if item_count_value < 1 || item_count_value > MAX_ITEMS || operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	item_count, operation_count := int(item_count_value), int(operation_count_value)
	if int(length) != 2 + 3 * operation_count do return -1

	for operation := 0; operation < operation_count; operation += 1 {
		position := 2 + 3 * operation
		opcode, first, second := input[position], input[position + 1], input[position + 2]
		if opcode == 0 {
			if first < 0 || first >= item_count_value || second < 0 || second >= item_count_value do return -1
		} else if opcode == 1 {
			if first < 0 || first >= item_count_value || second != 0 do return -1
		} else do return -1
	}

	var parent: [MAX_ITEMS]i64
	var successor: [MAX_ITEMS]i64
	for item := 0; item < item_count; item += 1 {
		parent[item] = -1
		successor[item] = i64(item)
	}
	checksum: i64 = 0
	for operation := 0; operation < operation_count; operation += 1 {
		position := 2 + 3 * operation
		opcode := input[position]
		first := int(input[position + 1])
		observed: i64 = 0
		if opcode == 0 {
			left := find_root(&parent[0], first)
			right := find_root(&parent[0], int(input[position + 2]))
			if left != right {
				if parent[left] > parent[right] { left, right = right, left }
				parent[left] += parent[right]
				parent[right] = i64(left)
				successor[left], successor[right] = successor[right], successor[left]
				observed = 1
			}
		} else {
			observed = component_mask(&successor[0], first)
		}
		checksum += i64(operation + 1) * (observed + 1)
	}
	return checksum
}
