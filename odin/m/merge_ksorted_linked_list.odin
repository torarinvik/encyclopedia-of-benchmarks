package merge_ksorted_linked_list

import "core:c"

MAX_LISTS :: 16
MAX_TOTAL_NODES :: 128
MAX_INPUT_LENGTH :: 145
MAX_OUTPUT_BYTES :: 512

Heap_Node :: struct {
	value: i64,
	list_index: int,
	node_index: int,
}
Heap :: [MAX_LISTS]Heap_Node

node_less :: proc "contextless" (left, right: Heap_Node) -> bool {
	if left.value != right.value do return left.value < right.value
	if left.list_index != right.list_index do return left.list_index < right.list_index
	return left.node_index < right.node_index
}

heap_push :: proc "contextless" (heap: ^Heap, size: ^int, node: Heap_Node) {
	index := size^
	size^ += 1
	for index > 0 {
		parent := (index - 1) / 2
		if !node_less(node, heap^[parent]) do break
		heap^[index] = heap^[parent]
		index = parent
	}
	heap^[index] = node
}

heap_pop :: proc "contextless" (heap: ^Heap, size: ^int) -> Heap_Node {
	result := heap^[0]
	size^ -= 1
	last := heap^[size^]
	if size^ > 0 {
		index := 0
		for index < size^ / 2 {
			child := 2 * index + 1
			if child + 1 < size^ && node_less(heap^[child + 1], heap^[child]) do child += 1
			if !node_less(heap^[child], last) do break
			heap^[index] = heap^[child]
			index = child
		}
		heap^[index] = last
	}
	return result
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset+byte] = u8(bits >> u32(8*byte))
	}
}

@(export)
merge_ksorted_linked_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 0 || input[0] > i64(MAX_LISTS) do return -1
	list_count := int(input[0])
	starts: [MAX_LISTS]int
	lengths: [MAX_LISTS]int
	position := 1
	total_nodes := 0
	for list_index := 0; list_index < list_count; list_index += 1 {
		if position >= int(length) do return -1
		declared := input[position]
		position += 1
		if declared < 0 || declared > i64(MAX_TOTAL_NODES-total_nodes) do return -1
		list_length := int(declared)
		if list_length > int(length)-position do return -1
		starts[list_index] = position
		lengths[list_index] = list_length
		for node := 0; node < list_length; node += 1 {
			value := input[position+node]
			if value < -2_147_483_648 || value > 2_147_483_647 ||
				(node > 0 && input[position+node-1] > value) do return -1
		}
		position += list_length
		total_nodes += list_length
	}
	if position != int(length) do return -1

	output_bytes := 4 * total_nodes
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	var heap: Heap
	heap_size := 0
	for list_index := 0; list_index < list_count; list_index += 1 {
		if lengths[list_index] > 0 {
			heap_push(&heap, &heap_size, Heap_Node{input[starts[list_index]], list_index, 0})
		}
	}

	buffer: [MAX_OUTPUT_BYTES]u8
	written := 0
	for heap_size > 0 {
		node := heap_pop(&heap, &heap_size)
		put_i32_le(&buffer[0], written, node.value)
		written += 4
		next_index := node.node_index + 1
		if next_index < lengths[node.list_index] {
			heap_push(&heap, &heap_size, Heap_Node{
				input[starts[node.list_index]+next_index], node.list_index, next_index,
			})
		}
	}

	for index := 0; index < output_bytes; index += 1 do output[index] = buffer[index]
	return i64(output_bytes)
}
