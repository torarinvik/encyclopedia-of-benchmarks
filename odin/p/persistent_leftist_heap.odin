package persistent_leftist_heap

import "core:c"

MAX_OPERATIONS :: 64
MAX_NODES :: 1024
MAX_INPUT_WORDS :: 193
MAX_HEAP_SIZE :: 128

Heap_Node :: struct { key: i64, left, right: int, npl, size: int }

meld :: proc "contextless" (nodes: [^]Heap_Node, used: ^int, first_root, second_root: int) -> int {
	if first_root == 0 do return second_root
	if second_root == 0 do return first_root
	first, second := first_root, second_root
	if nodes[first].key > nodes[second].key { first, second = second, first }
	if used^ >= MAX_NODES do return -1
	copy := used^
	used^ += 1
	nodes[copy] = nodes[first]
	merged_right := meld(nodes, used, nodes[copy].right, second)
	if merged_right < 0 do return -1
	nodes[copy].right = merged_right
	if nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl {
		nodes[copy].left, nodes[copy].right = nodes[copy].right, nodes[copy].left
	}
	nodes[copy].npl = nodes[nodes[copy].right].npl + 1
	nodes[copy].size = nodes[nodes[copy].left].size + nodes[nodes[copy].right].size + 1
	return copy
}

@(export)
persistent_leftist_heap :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_WORDS) do return -1
	operation_count64 := input[0]
	if operation_count64 < 0 || operation_count64 > MAX_OPERATIONS do return -1
	operation_count := int(operation_count64)
	input_length := int(length)
	var nodes: [MAX_NODES]Heap_Node
	nodes[0].npl = -1
	used := 1
	var roots: [MAX_OPERATIONS + 1]int
	cursor := 1
	rank_sum: i64 = 0
	rank_xor: i64 = 0
	for operation := 0; operation < operation_count; operation += 1 {
		if cursor >= input_length do return -1
		kind := input[cursor]
		cursor += 1
		if kind == 0 {
			if cursor+2 > input_length do return -1
			base64, key := input[cursor], input[cursor+1]
			cursor += 2
			if base64 < 0 || base64 > i64(operation) || key < -10000 || key > 10000 do return -1
			base := int(base64)
			if nodes[roots[base]].size >= MAX_HEAP_SIZE || used >= MAX_NODES do return -1
			singleton := used
			used += 1
			nodes[singleton] = Heap_Node{key = key, npl = 0, size = 1}
			result_root := meld(&nodes[0], &used, roots[base], singleton)
			if result_root < 0 || nodes[result_root].size > MAX_HEAP_SIZE do return -1
			roots[operation+1] = result_root
		} else if kind == 1 {
			if cursor+2 > input_length do return -1
			left64, right64 := input[cursor], input[cursor+1]
			cursor += 2
			if left64 < 0 || left64 > i64(operation) || right64 < 0 || right64 > i64(operation) do return -1
			left_version, right_version := int(left64), int(right64)
			if nodes[roots[left_version]].size + nodes[roots[right_version]].size > MAX_HEAP_SIZE do return -1
			result_root := meld(&nodes[0], &used, roots[left_version], roots[right_version])
			if result_root < 0 || nodes[result_root].size > MAX_HEAP_SIZE do return -1
			roots[operation+1] = result_root
		} else if kind == 2 {
			if cursor+1 > input_length do return -1
			version64 := input[cursor]
			cursor += 1
			if version64 < 0 || version64 > i64(operation) do return -1
			root := roots[int(version64)]
			if root == 0 {
				roots[operation+1] = 0
				rank_sum += 20001
				rank_xor = rank_xor ~ 20001
			} else {
				rank := nodes[root].key + 10000
				rank_sum += rank
				rank_xor = rank_xor ~ rank
				result_root := meld(&nodes[0], &used, nodes[root].left, nodes[root].right)
				if result_root < 0 || nodes[result_root].size > MAX_HEAP_SIZE do return -1
				roots[operation+1] = result_root
			}
		} else if kind == 3 {
			if cursor+1 > input_length do return -1
			version64 := input[cursor]
			cursor += 1
			if version64 < 0 || version64 > i64(operation) do return -1
			root := roots[int(version64)]
			roots[operation+1] = root
			rank: i64 = 20001
			if root != 0 do rank = nodes[root].key + 10000
			rank_sum += rank
			rank_xor = rank_xor ~ rank
		} else {
			return -1
		}
	}
	if cursor != input_length do return -1
	return (rank_sum << 15) | rank_xor
}
