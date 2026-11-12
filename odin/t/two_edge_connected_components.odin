package two_edge_connected_components

import "core:c"

MAX_N :: 6
MAX_M :: 10
MAX_ADJ :: 20
MAX_OUTPUT_VALUES :: 13
MAX_OUTPUT_BYTES :: 104
MAX_INPUT_LENGTH :: 22

Context :: struct {
	n, m: int,
	degree: [6]int,
	adjacent_vertex, adjacent_edge: [120]int,
	discovery, low: [6]int,
	is_bridge: [10]bool,
	clock: int,
	component: [6]int,
	block_vertices: [36]int,
	block_size: [6]int,
	block_count: int,
}

find_bridges :: proc "contextless" (context: ^Context, vertex, parent_edge: int) {
	context.discovery[vertex] = context.clock
	context.low[vertex] = context.clock
	context.clock += 1
	for slot := 0; slot < context.degree[vertex]; slot += 1 {
		index := vertex * MAX_ADJ + slot
		neighbor := context.adjacent_vertex[index]
		edge := context.adjacent_edge[index]
		if edge == parent_edge do continue
		if context.discovery[neighbor] < 0 {
			find_bridges(context, neighbor, edge)
			if context.low[neighbor] < context.low[vertex] do context.low[vertex] = context.low[neighbor]
			if context.low[neighbor] > context.discovery[vertex] do context.is_bridge[edge] = true
		} else if context.discovery[neighbor] < context.low[vertex] {
			context.low[vertex] = context.discovery[neighbor]
		}
	}
}

assign_components :: proc "contextless" (context: ^Context) {
	queue: [MAX_N]int
	for root := 0; root < context.n; root += 1 {
		if context.component[root] >= 0 do continue
		block := context.block_count
		context.block_count += 1
		head, tail := 0, 0
		context.component[root] = block
		queue[tail] = root
		tail += 1
		for head < tail {
			vertex := queue[head]
			head += 1
			for slot := 0; slot < context.degree[vertex]; slot += 1 {
				index := vertex * MAX_ADJ + slot
				neighbor := context.adjacent_vertex[index]
				edge := context.adjacent_edge[index]
				if context.is_bridge[edge] || context.component[neighbor] >= 0 do continue
				context.component[neighbor] = block
				queue[tail] = neighbor
				tail += 1
			}
		}
		for vertex := 0; vertex < context.n; vertex += 1 {
			if context.component[vertex] == block {
				context.block_vertices[block * MAX_N + context.block_size[block]] = vertex
				context.block_size[block] += 1
			}
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
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8((value >> u64(byte * 8)) & 255)
}

// Return the packed component output byte count, or a contract error.
@(export)
two_edge_connected_components :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < c.size_t(2) || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2 + 2 * m) do return -1

	context := Context{}
	context.n, context.m = n, m
	for vertex := 0; vertex < n; vertex += 1 {
		context.discovery[vertex] = -1
		context.component[vertex] = -1
	}
	for edge := 0; edge < m; edge += 1 {
		left_value, right_value := input[2 + 2 * edge], input[3 + 2 * edge]
		if left_value < 0 || left_value >= i64(n) || right_value < 0 || right_value >= i64(n) do return -1
		left, right := int(left_value), int(right_value)
		left_slot := context.degree[left]
		context.degree[left] += 1
		right_slot := context.degree[right]
		context.degree[right] += 1
		context.adjacent_vertex[left * MAX_ADJ + left_slot] = right
		context.adjacent_edge[left * MAX_ADJ + left_slot] = edge
		context.adjacent_vertex[right * MAX_ADJ + right_slot] = left
		context.adjacent_edge[right * MAX_ADJ + right_slot] = edge
	}
	for root := 0; root < n; root += 1 {
		if context.discovery[root] < 0 do find_bridges(&context, root, MAX_M)
	}
	assign_components(&context)

	order: [MAX_N]int
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
