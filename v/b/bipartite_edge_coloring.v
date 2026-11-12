module bipartite_edge_coloring

const max_side = 5
const max_edges = 10
const max_input_length = 23
const max_output_bytes = 88

fn augment_matching(left int, side int, multiplicity &i64, mut seen &bool,
	mut match_right &i32) bool {
	for right in 0 .. side {
		index := left * max_side + right
		if unsafe { multiplicity[index] == 0 || seen[right] } { continue }
		unsafe { seen[right] = true }
		mate := unsafe { match_right[right] }
		if mate < 0 || augment_matching(int(mate), side, multiplicity, mut seen, mut match_right) {
			unsafe { match_right[right] = i32(left) }
			return true
		}
	}
	return false
}

fn store_u64_le(mut output &u8, offset int, value u64) {
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((value >> u64(byte * 8)) & 255) }
	}
}

// Color all edges optimally; return output byte length or a contract error.
@[export: 'bipartite_edge_coloring']
pub fn bipartite_edge_coloring(input &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		left_value, right_value, edge_value := input[0], input[1], input[2]
		if left_value < 1 || left_value > max_side || right_value < 1 || right_value > max_side ||
			edge_value < 1 || edge_value > max_edges { return -1 }
		left_count, right_count, edge_count := int(left_value), int(right_value), int(edge_value)
		if length != usize(3 + 2 * edge_count) { return -1 }

		mut multiplicity := [max_side * max_side]i64{}
		mut original_remaining := [max_side * max_side]i64{}
		mut left_degree := [max_side]int{}
		mut right_degree := [max_side]int{}
		mut edge_left := [max_edges]int{}
		mut edge_right := [max_edges]int{}
		for edge in 0 .. edge_count {
			left := input[3 + 2 * edge]
			right := input[4 + 2 * edge]
			if left < 0 || left >= left_value || right < 0 || right >= right_value { return -1 }
			u, v := int(left), int(right)
			edge_left[edge], edge_right[edge] = u, v
			index := u * max_side + v
			multiplicity[index]++
			original_remaining[index]++
			left_degree[u]++
			right_degree[v]++
		}

		side := if left_count > right_count { left_count } else { right_count }
		mut maximum_degree := 0
		for vertex in 0 .. side {
			if left_degree[vertex] > maximum_degree { maximum_degree = left_degree[vertex] }
			if right_degree[vertex] > maximum_degree { maximum_degree = right_degree[vertex] }
		}
		for {
			mut left := 0
			for left < side && left_degree[left] == maximum_degree { left++ }
			if left == side { break }
			mut right := 0
			for right < side && right_degree[right] == maximum_degree { right++ }
			if right == side { return -1 }
			index := left * max_side + right
			multiplicity[index]++
			left_degree[left]++
			right_degree[right]++
		}

		mut colors := [max_edges]i64{}
		for edge in 0 .. edge_count { colors[edge] = -1 }
		for color in 0 .. maximum_degree {
			mut match_right := [max_side]i32{}
			for right in 0 .. side { match_right[right] = -1 }
			for left in 0 .. side {
				mut seen := [max_side]bool{}
				if !augment_matching(left, side, &multiplicity[0], mut seen[0], mut match_right[0]) { return -1 }
			}
			for right in 0 .. side {
				left := int(match_right[right])
				if left < 0 { return -1 }
				index := left * max_side + right
				if original_remaining[index] > 0 {
					mut edge := 0
					for edge < edge_count && (colors[edge] >= 0 || edge_left[edge] != left || edge_right[edge] != right) { edge++ }
					if edge == edge_count { return -1 }
					colors[edge] = i64(color)
					original_remaining[index]--
				}
				multiplicity[index]--
			}
		}

		bytes := 8 * (edge_count + 1)
		if output == nil || output_capacity < usize(bytes) { return -2 }
		mut staged := [max_output_bytes]u8{}
		store_u64_le(mut staged[0], 0, u64(maximum_degree))
		for edge in 0 .. edge_count { store_u64_le(mut staged[0], 8 * (edge + 1), u64(colors[edge])) }
		for byte in 0 .. bytes { output[byte] = staged[byte] }
		return i64(bytes)
	}
}
