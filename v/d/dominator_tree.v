module dominator_tree

const max_vertex_count = 63
const max_edge_count = 2047
const max_input_length = 3 + 2 * max_edge_count

fn count_bits(value u64) int {
	mut remaining := value
	mut count := 0
	for remaining != 0 {
		remaining &= remaining - 1
		count++
	}
	return count
}

@[export: 'dominator_tree']
pub fn dominator_tree(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 3 || length > max_input_length { return -1 }
	unsafe {
		if input == nil { return -1 }
		if input[0] < 1 || input[0] > max_vertex_count || input[1] < 0 ||
			input[1] >= input[0] || input[2] < 0 || input[2] > max_edge_count { return -1 }
		vertex_count := int(input[0])
		root := int(input[1])
		edge_count := int(input[2])
		if int(length) != 3 + 2 * edge_count { return -1 }
		mut outgoing := []u64{len: max_vertex_count}
		for edge in 0 .. edge_count {
			from_value := input[3 + 2 * edge]
			to_value := input[4 + 2 * edge]
			if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) ||
				to_value >= i64(vertex_count) { return -1 }
			outgoing[int(from_value)] |= u64(1) << int(to_value)
		}
		mut reachable := u64(1) << root
		mut frontier := reachable
		for frontier != 0 {
			mut discovered := u64(0)
			for vertex in 0 .. vertex_count {
				if frontier & (u64(1) << vertex) != 0 { discovered |= outgoing[vertex] }
			}
			discovered &= ~reachable
			reachable |= discovered
			frontier = discovered
		}
		mut dominators := []u64{len: max_vertex_count}
		dominators[root] = u64(1) << root
		for vertex in 0 .. vertex_count {
			if reachable & (u64(1) << vertex) != 0 && vertex != root { dominators[vertex] = reachable }
		}
		mut changed := true
		for changed {
			changed = false
			for vertex in 0 .. vertex_count {
				vertex_bit := u64(1) << vertex
				if reachable & vertex_bit == 0 || vertex == root { continue }
				mut common := reachable
				for predecessor in 0 .. vertex_count {
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
		if output == nil || output_capacity < usize(vertex_count) { return -2 }
		mut position := 0
		for vertex in 0 .. vertex_count {
			vertex_bit := u64(1) << vertex
			if reachable & vertex_bit == 0 {
				output[position] = u8(255)
			} else if vertex == root {
				output[position] = u8(root)
			} else {
				strict := dominators[vertex] & ~vertex_bit
				mut best := root
				mut best_depth := 0
				for candidate in 0 .. vertex_count {
					if strict & (u64(1) << candidate) == 0 { continue }
					depth := count_bits(dominators[candidate])
					if depth > best_depth {
						best = candidate
						best_depth = depth
					}
				}
				output[position] = u8(best)
			}
			position++
		}
		return i64(vertex_count)
	}
}
