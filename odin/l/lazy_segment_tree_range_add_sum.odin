package lazy_segment_tree_range_add_sum

import "core:c"

MAX_ITEMS :: 256
MAX_OPERATIONS :: 512
MAX_INPUT_LENGTH :: 2306
VALUE_LIMIT :: i64(1_000_000)
QUERY_OFFSET :: i64(131_328_000_001)

apply :: proc(tree, pending: [^]i64, node, segment_length: int, delta: i64) {
	tree[node] += delta * i64(segment_length)
	pending[node] += delta
}

push :: proc(tree, pending: [^]i64, node, segment_length: int) {
	if segment_length > 1 && pending[node] != 0 {
		child_length := segment_length / 2
		apply(tree, pending, 2 * node, child_length, pending[node])
		apply(tree, pending, 2 * node + 1, child_length, pending[node])
		pending[node] = 0
	}
}

range_add :: proc(tree, pending: [^]i64, node, low, high, query_low, query_high: int, delta: i64) {
	if query_low <= low && high <= query_high {
		apply(tree, pending, node, high - low, delta)
		return
	}
	push(tree, pending, node, high - low)
	middle := (low + high) / 2
	if query_low < middle do range_add(tree, pending, 2 * node, low, middle, query_low, query_high, delta)
	if query_high > middle do range_add(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta)
	tree[node] = tree[2 * node] + tree[2 * node + 1]
}

range_sum :: proc(tree, pending: [^]i64, node, low, high, query_low, query_high: int) -> i64 {
	if query_low <= low && high <= query_high do return tree[node]
	push(tree, pending, node, high - low)
	middle := (low + high) / 2
	result: i64 = 0
	if query_low < middle do result += range_sum(tree, pending, 2 * node, low, middle, query_low, query_high)
	if query_high > middle do result += range_sum(tree, pending, 2 * node + 1, middle, high, query_low, query_high)
	return result
}

@(export)
lazy_segment_tree_range_add_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	item_count_value := values[0]
	if item_count_value < 1 || item_count_value > MAX_ITEMS do return -1
	item_count := int(item_count_value)
	if length < c.size_t(item_count + 2) do return -1
	operation_count_value := values[item_count + 1]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	if length != c.size_t(item_count + 2 + 4 * operation_count) do return -1

	for index := 0; index < item_count; index += 1 {
		if values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT do return -1
	}
	for operation := 0; operation < operation_count; operation += 1 {
		position := item_count + 2 + 4 * operation
		opcode, left, right, delta := values[position], values[position + 1], values[position + 2], values[position + 3]
		if left < 0 || left >= right || right > item_count_value do return -1
		if opcode == 0 {
			if delta < -VALUE_LIMIT || delta > VALUE_LIMIT do return -1
		} else if opcode == 1 {
			if delta != 0 do return -1
		} else do return -1
	}

	base := 1
	for base < item_count { base *= 2 }
	tree: [512]i64
	pending: [512]i64
	for index := 0; index < 2 * base; index += 1 {
		tree[index] = 0
		pending[index] = 0
	}
	for index := 0; index < item_count; index += 1 { tree[base + index] = values[index + 1] }
	node := base
	for node > 1 {
		node--
		tree[node] = tree[2 * node] + tree[2 * node + 1]
	}

	checksum: i64 = 0
	for operation := 0; operation < operation_count; operation++ {
		position := item_count + 2 + 4 * operation
		left := int(values[position + 1])
		right := int(values[position + 2])
		if values[position] == 0 {
			range_add(&tree[0], &pending[0], 1, 0, base, left, right, values[position + 3])
		} else {
			checksum += range_sum(&tree[0], &pending[0], 1, 0, base, left, right) + QUERY_OFFSET
		}
	}
	return checksum
}
