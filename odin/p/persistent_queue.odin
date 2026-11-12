package persistent_queue

import "core:c"

MAX_Q :: 128
TREE_BASE :: 128
TREE_HEIGHT :: 7
MAX_NODES :: 1 + MAX_Q * (TREE_HEIGHT + 1)
MAX_PARSEABLE_INPUT :: 1 + 3 * MAX_Q + 1
MAX_VALUE :: i64(1_000_000_000)

Node :: struct { left, right: int; value: i64 }

set_value :: proc "contextless" (nodes: [^]Node, used: ^int, root, low, high, position: int, value: i64) -> int {
	copy := used^
	used^ = used^ + 1
	nodes[copy] = nodes[root]
	if high-low == 1 {
		nodes[copy].value = value
		return copy
	}
	middle := low + (high-low)/2
	if position < middle {
		child := set_value(nodes, used, nodes[root].left, low, middle, position, value)
		nodes[copy].left = child
	} else {
		child := set_value(nodes, used, nodes[root].right, middle, high, position, value)
		nodes[copy].right = child
	}
	return copy
}

get_value :: proc "contextless" (nodes: [^]Node, root, low, high, position: int) -> i64 {
	if high-low == 1 do return nodes[root].value
	middle := low + (high-low)/2
	if position < middle do return get_value(nodes, nodes[root].left, low, middle, position)
	return get_value(nodes, nodes[root].right, middle, high, position)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> (byte*8)) }
}

@(export)
persistent_queue :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT) do return -1
	qv := input[0]
	if qv < 1 || qv > MAX_Q do return -1
	q := int(qv)
	var kind, parent, value: [MAX_Q]i64
	var version_head, version_tail, version_size: [MAX_Q+1]int
	mut cursor, pop_count := 1, 0
	for operation := 0; operation < q; operation += 1 {
		if cursor+2 > int(length) do return -1
		kind[operation] = input[cursor]
		cursor += 1
		parent[operation] = input[cursor]
		cursor += 1
		if (kind[operation] != 0 && kind[operation] != 1) || parent[operation] < -1 || parent[operation] >= i64(operation) do return -1
		base := int(parent[operation]+1)
		if kind[operation] == 0 {
			if cursor >= int(length) do return -1
			value[operation] = input[cursor]
			cursor += 1
			if value[operation] < 0 || value[operation] > MAX_VALUE || version_tail[base] >= TREE_BASE do return -1
			version_head[operation+1] = version_head[base]
			version_tail[operation+1] = version_tail[base]+1
			version_size[operation+1] = version_size[base]+1
		} else {
			if version_size[base] == 0 do return -1
			version_head[operation+1] = version_head[base]+1
			version_tail[operation+1] = version_tail[base]
			version_size[operation+1] = version_size[base]-1
			pop_count += 1
		}
	}
	if cursor != int(length) do return -1
	required := 8*pop_count
	if required > 0 && (output == nil || capacity < c.size_t(required)) do return -2

	var nodes: [MAX_NODES]Node
	var roots: [MAX_Q+1]int
	var answers: [MAX_Q]i64
	mut used, answer_count := 1, 0
	for operation := 0; operation < q; operation += 1 {
		base := int(parent[operation]+1)
		version := operation+1
		if kind[operation] == 0 {
			roots[version] = set_value(&nodes[0], &used, roots[base], 0, TREE_BASE,
				version_tail[base], value[operation])
		} else {
			answers[answer_count] = get_value(&nodes[0], roots[base], 0, TREE_BASE, version_head[base])
			answer_count += 1
			roots[version] = roots[base]
		}
	}
	for index := 0; index < answer_count; index += 1 { store_i64_le(&output[0], 8*index, answers[index]) }
	return i64(required)
}
