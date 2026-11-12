package biconnected_components

import "core:c"

MAX_N :: 6
MAX_M :: 10
MAX_ADJ :: 20
MAX_BLOCKS :: MAX_N + MAX_M
MAX_OUTPUT_VALUES :: 113
MAX_OUTPUT_BYTES :: 904
MAX_INPUT_LENGTH :: 22

Context :: struct {
	n, m: int,
	edge_left, edge_right: [10]int,
	degree: [6]int,
	adjacent_vertex, adjacent_edge: [120]int,
	discovery, low: [6]int,
	edge_stack: [10]int,
	stack_size, clock: int,
	block_vertices: [96]int,
	block_size: [16]int,
	block_count: int,
}

append_block :: proc "contextless" (context: ^Context, stop_edge: int) {
	member: [MAX_N]bool
	for context.stack_size > 0 {
		context.stack_size -= 1
		edge := context.edge_stack[context.stack_size]
		member[context.edge_left[edge]] = true
		member[context.edge_right[edge]] = true
		if edge == stop_edge do break
	}
	block := context.block_count
	context.block_count += 1
	for vertex := 0; vertex < context.n; vertex += 1 {
		if member[vertex] {
			context.block_vertices[block * MAX_N + context.block_size[block]] = vertex
			context.block_size[block] += 1
		}
	}
}

visit :: proc "contextless" (context: ^Context, vertex, parent_edge: int) {
	context.discovery[vertex] = context.clock
	context.low[vertex] = context.clock
	context.clock += 1
	for slot := 0; slot < context.degree[vertex]; slot += 1 {
		index := vertex * MAX_ADJ + slot
		neighbor := context.adjacent_vertex[index]
		edge := context.adjacent_edge[index]
		if edge == parent_edge do continue
		if context.discovery[neighbor] < 0 {
			context.edge_stack[context.stack_size] = edge
			context.stack_size += 1
			visit(context, neighbor, edge)
			if context.low[neighbor] < context.low[vertex] do context.low[vertex] = context.low[neighbor]
			if context.low[neighbor] >= context.discovery[vertex] do append_block(context, edge)
		} else if context.discovery[neighbor] < context.discovery[vertex] {
			context.edge_stack[context.stack_size] = edge
			context.stack_size += 1
			if context.discovery[neighbor] < context.low[vertex] do context.low[vertex] = context.discovery[neighbor]
		}
	}
}

block_less :: proc "contextless" (context: ^Context, left, right: int) -> bool {
	common := context.block_size[left]
	if context.block_size[right] < common do common = context.block_size[right]
	for i := 0; i < common; i += 1 {
		a := context.block_vertices[left * MAX_N + i]
		b := context.block_vertices[right * MAX_N + i]
		if a != b do return a < b
	}
	return context.block_size[left] < context.block_size[right]
}

store_u64_le :: proc "contextless" (output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((value >> u64(byte * 8)) & 255)
	}
}

// Return the packed vertex-block output byte count, or a contract error.
@(export)
biconnected_components :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < c.size_t(2) || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2 + 2 * m) do return -1

	context := Context{}
	context.n, context.m = n, m
	for vertex := 0; vertex < n; vertex += 1 do context.discovery[vertex] = -1
	for edge := 0; edge < m; edge += 1 {
		left_value, right_value := input[2 + 2 * edge], input[3 + 2 * edge]
		if left_value < 0 || left_value >= i64(n) || right_value < 0 || right_value >= i64(n) ||
			left_value == right_value do return -1
		left, right := int(left_value), int(right_value)
		context.edge_left[edge], context.edge_right[edge] = left, right
		left_slot, right_slot := context.degree[left], context.degree[right]
		context.degree[left] += 1
		context.degree[right] += 1
		context.adjacent_vertex[left * MAX_ADJ + left_slot] = right
		context.adjacent_edge[left * MAX_ADJ + left_slot] = edge
		context.adjacent_vertex[right * MAX_ADJ + right_slot] = left
		context.adjacent_edge[right * MAX_ADJ + right_slot] = edge
	}
	for root := 0; root < n; root += 1 {
		if context.discovery[root] >= 0 do continue
		visit(&context, root, MAX_M)
		if context.degree[root] == 0 {
			block := context.block_count
			context.block_count += 1
			context.block_vertices[block * MAX_N] = root
			context.block_size[block] = 1
		}
	}

	order: [MAX_BLOCKS]int
	for i := 0; i < context.block_count; i += 1 {
		position := i
		order[i] = i
		for position > 0 && block_less(&context, order[position], order[position - 1]) {
			temporary := order[position]
			order[position] = order[position - 1]
			order[position - 1] = temporary
			position -= 1
		}
	}
	staged: [MAX_OUTPUT_BYTES]u8
	packed_count := 0
	store_u64_le(&staged[0], packed_count * 8, u64(context.block_count))
	packed_count += 1
	for i := 0; i < context.block_count; i += 1 {
		block := order[i]
		store_u64_le(&staged[0], packed_count * 8, u64(context.block_size[block]))
		packed_count += 1
		for j := 0; j < context.block_size[block]; j += 1 {
			store_u64_le(&staged[0], packed_count * 8, u64(context.block_vertices[block * MAX_N + j]))
			packed_count += 1
		}
	}
	bytes := 8 * packed_count
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	for byte := 0; byte < bytes; byte += 1 do output[byte] = staged[byte]
	return i64(bytes)
}
