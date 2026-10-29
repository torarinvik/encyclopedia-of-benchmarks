package dominator_tree

import "core:c"

MAX_VERTEX_COUNT :: 63
MAX_EDGE_COUNT :: 2047
MAX_INPUT_LENGTH :: 3 + 2 * MAX_EDGE_COUNT

count_bits :: proc(value: u64) -> int {
	remaining := value
	count := 0
	for remaining != 0 {
		remaining &= remaining - 1
		count += 1
	}
	return count
}

@(export)
dominator_tree :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 ||
		input[1] >= input[0] || input[2] < 0 || input[2] > MAX_EDGE_COUNT do return -1
	vertex_count := int(input[0])
	root := int(input[1])
	edge_count := int(input[2])
	if int(length) != 3 + 2 * edge_count do return -1

	outgoing: [MAX_VERTEX_COUNT]u64
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 { outgoing[vertex] = 0 }
	for edge := 0; edge < edge_count; edge += 1 {
		from_value := input[3 + 2 * edge]
		to_value := input[4 + 2 * edge]
		if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) ||
			to_value >= i64(vertex_count) do return -1
		outgoing[int(from_value)] |= u64(1) << int(to_value)
	}

	reachable := u64(1) << root
	frontier := reachable
	for frontier != 0 {
		discovered: u64 = 0
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			if frontier & (u64(1) << vertex) != 0 do discovered |= outgoing[vertex]
		}
		discovered &= ~reachable
		reachable |= discovered
		frontier = discovered
	}

	dominators: [MAX_VERTEX_COUNT]u64
	for vertex := 0; vertex < MAX_VERTEX_COUNT; vertex += 1 { dominators[vertex] = 0 }
	dominators[root] = u64(1) << root
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		if reachable & (u64(1) << vertex) != 0 && vertex != root do dominators[vertex] = reachable
	}

	changed := true
	for changed {
		changed = false
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			vertex_bit := u64(1) << vertex
			if reachable & vertex_bit == 0 || vertex == root do continue
			common := reachable
			for predecessor := 0; predecessor < vertex_count; predecessor += 1 {
				if reachable & (u64(1) << predecessor) != 0 && outgoing[predecessor] & vertex_bit != 0 {
					common &= dominators[predecessor]
				}
			}
			updated := common | vertex_bit
			if updated != dominators[vertex] {
				dominators[vertex] = updated
				changed = true
			}
		}
	}

	if output == nil || output_capacity < c.size_t(vertex_count) do return -2
	for vertex := 0; vertex < vertex_count; vertex += 1 {
		vertex_bit := u64(1) << vertex
		if reachable & vertex_bit == 0 {
			output[vertex] = 255
		} else if vertex == root {
			output[vertex] = u8(root)
		} else {
			strict := dominators[vertex] & ~vertex_bit
			best := root
			best_depth := 0
			for candidate := 0; candidate < vertex_count; candidate += 1 {
				if strict & (u64(1) << candidate) == 0 do continue
				depth := count_bits(dominators[candidate])
				if depth > best_depth {
					best = candidate
					best_depth = depth
				}
			}
			output[vertex] = u8(best)
		}
	}
	return i64(vertex_count)
}
