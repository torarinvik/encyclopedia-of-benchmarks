package redundant_connection

import "core:c"

MAX_VERTICES :: 1000

find_root :: proc "contextless" (parents: [^]i32, node_value: i32) -> i32 {
	node := node_value
	root := node
	for parents[int(root)] != root do root = parents[int(root)]
	for parents[int(node)] != node {
		next := parents[int(node)]
		parents[int(node)] = root
		node = next
	}
	return root
}

// Return the edge that first closes the cycle under input-order union-find.
@(export)
redundant_connection :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 6 || length > MAX_VERTICES*2 || length % 2 != 0 || values == nil do return -1
	edge_count := int(length / 2)
	for index := 0; index < int(length); index += 1 {
		if values[index] < 1 || values[index] > i64(edge_count) do return -1
	}
	for edge := 0; edge < edge_count; edge += 1 {
		if values[2*edge] == values[2*edge+1] do return -1
	}

	parents: [MAX_VERTICES+1]i32
	for node := 0; node <= edge_count; node += 1 { parents[node] = i32(node) }
	redundant_left := i64(0)
	redundant_right := i64(0)
	redundant_count := 0
	for edge := 0; edge < edge_count; edge += 1 {
		left := int(values[2*edge])
		right := int(values[2*edge+1])
		left_root := find_root(&parents[0], i32(left))
		right_root := find_root(&parents[0], i32(right))
		if left_root == right_root {
			redundant_left = i64(left)
			redundant_right = i64(right)
			redundant_count += 1
		} else {
			parents[int(left_root)] = right_root
		}
	}
	if redundant_count != 1 do return -1
	if output_capacity < 8 || output == nil do return -2
	for endpoint := 0; endpoint < 2; endpoint += 1 {
		value := redundant_left
		if endpoint == 1 { value = redundant_right }
		bits := u32(value)
		for byte := 0; byte < 4; byte += 1 {
			output[endpoint*4+byte] = u8((bits >> u32(byte*8)) & 255)
		}
	}
	return 2
}
