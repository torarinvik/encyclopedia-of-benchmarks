package bipartite_edge_coloring

import "core:c"

MAX_SIDE_VERTICES :: 5
MAX_EDGES :: 10
MAX_INPUT_LENGTH :: 23
MAX_OUTPUT_BYTES :: 88

Context :: struct {
	multiplicity: [25]int,
	original_remaining: [25]int,
	left_degree: [5]int,
	right_degree: [5]int,
	seen: [5]bool,
	match_right: [5]int,
}

augment_matching :: proc "contextless" (context: ^Context, left, side: int) -> bool {
	for right := 0; right < side; right += 1 {
		index := left * MAX_SIDE_VERTICES + right
		if context.multiplicity[index] == 0 || context.seen[right] do continue
		context.seen[right] = true
		mate := context.match_right[right]
		if mate < 0 || augment_matching(context, mate, side) {
			context.match_right[right] = left
			return true
		}
	}
	return false
}

store_u64_le :: proc "contextless" (output: [^]u8, offset: int, value: u64) {
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((value >> u64(byte * 8)) & 255)
	}
}

// Color each edge with the minimum number of colors; return byte length or an error code.
@(export)
bipartite_edge_coloring :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	left_value, right_value, edge_value := input[0], input[1], input[2]
	if left_value < 1 || left_value > MAX_SIDE_VERTICES || right_value < 1 ||
		right_value > MAX_SIDE_VERTICES || edge_value < 1 || edge_value > MAX_EDGES do return -1
	left_count, right_count, edge_count := int(left_value), int(right_value), int(edge_value)
	if int(length) != 3 + 2 * edge_count do return -1

	context: Context
	edge_left: [10]int
	edge_right: [10]int
	for edge := 0; edge < edge_count; edge += 1 {
		left_value_edge := input[3 + 2 * edge]
		right_value_edge := input[4 + 2 * edge]
		if left_value_edge < 0 || left_value_edge >= left_value || right_value_edge < 0 ||
			right_value_edge >= right_value do return -1
		left, right := int(left_value_edge), int(right_value_edge)
		edge_left[edge], edge_right[edge] = left, right
		index := left * MAX_SIDE_VERTICES + right
		context.multiplicity[index] += 1
		context.original_remaining[index] += 1
		context.left_degree[left] += 1
		context.right_degree[right] += 1
	}

	side := left_count
	if right_count > side do side = right_count
	maximum_degree := 0
	for vertex := 0; vertex < side; vertex += 1 {
		if context.left_degree[vertex] > maximum_degree do maximum_degree = context.left_degree[vertex]
		if context.right_degree[vertex] > maximum_degree do maximum_degree = context.right_degree[vertex]
	}
	for {
		left := 0
		for left < side && context.left_degree[left] == maximum_degree do left += 1
		if left == side do break
		right := 0
		for right < side && context.right_degree[right] == maximum_degree do right += 1
		if right == side do return -1
		index := left * MAX_SIDE_VERTICES + right
		context.multiplicity[index] += 1
		context.left_degree[left] += 1
		context.right_degree[right] += 1
	}

	colors: [10]i64
	for edge := 0; edge < edge_count; edge += 1 do colors[edge] = -1
	for color := 0; color < maximum_degree; color += 1 {
		for right := 0; right < side; right += 1 do context.match_right[right] = -1
		for left := 0; left < side; left += 1 {
			for right := 0; right < side; right += 1 do context.seen[right] = false
			if !augment_matching(&context, left, side) do return -1
		}
		for right := 0; right < side; right += 1 {
			left := context.match_right[right]
			if left < 0 do return -1
			index := left * MAX_SIDE_VERTICES + right
			if context.original_remaining[index] > 0 {
				edge := 0
				for edge < edge_count && (colors[edge] >= 0 || edge_left[edge] != left || edge_right[edge] != right) do edge += 1
				if edge == edge_count do return -1
				colors[edge] = i64(color)
				context.original_remaining[index] -= 1
			}
			context.multiplicity[index] -= 1
		}
	}

	bytes := 8 * (edge_count + 1)
	if output == nil || int(output_capacity) < bytes do return -2
	staged: [88]u8
	store_u64_le(&staged[0], 0, u64(maximum_degree))
	for edge := 0; edge < edge_count; edge += 1 {
		store_u64_le(&staged[0], 8 * (edge + 1), u64(colors[edge]))
	}
	for byte := 0; byte < bytes; byte += 1 do output[byte] = staged[byte]
	return i64(bytes)
}
