module bridges

const max_vertex_count = 64
const max_edge_count = 2047
const max_input_length = 2 + 2 * max_edge_count

struct GraphState {
	mut:
	adjacency [max_vertex_count]u64
	bridge_mask [max_vertex_count]u64
	discovery [max_vertex_count]int
	low [max_vertex_count]int
	parent [max_vertex_count]int
}

fn visit_vertex(mut state GraphState, vertex_count int, vertex int, mut time int) {
	state.discovery[vertex] = time
	state.low[vertex] = time
	time++
	for neighbor in 0 .. vertex_count {
		if state.adjacency[vertex] & (u64(1) << neighbor) == 0 { continue }
		if state.discovery[neighbor] == -1 {
			state.parent[neighbor] = vertex
			visit_vertex(mut state, vertex_count, neighbor, mut time)
			if state.low[neighbor] < state.low[vertex] { state.low[vertex] = state.low[neighbor] }
			if state.low[neighbor] > state.discovery[vertex] {
				state.bridge_mask[vertex] |= u64(1) << neighbor
				state.bridge_mask[neighbor] |= u64(1) << vertex
			}
		} else if neighbor != state.parent[vertex] && state.discovery[neighbor] < state.low[vertex] {
			state.low[vertex] = state.discovery[neighbor]
		}
	}
}

@[export: 'bridges']
pub fn bridges(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_vertex_count || input[1] < 0 || input[1] > max_edge_count { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if int(length) != 2 + 2 * edge_count { return -1 }
		mut state := GraphState{}
		for edge in 0 .. edge_count {
			left_value := input[2 + 2 * edge]
			right_value := input[3 + 2 * edge]
			if left_value < 0 || right_value < 0 || left_value >= i64(vertex_count) || right_value >= i64(vertex_count) { return -1 }
			left := int(left_value)
			right := int(right_value)
			state.adjacency[left] |= u64(1) << right
			state.adjacency[right] |= u64(1) << left
		}
		for vertex in 0 .. vertex_count {
			state.discovery[vertex] = -1
			state.parent[vertex] = -1
		}
		mut time := 0
		for vertex in 0 .. vertex_count {
			if state.discovery[vertex] == -1 { visit_vertex(mut state, vertex_count, vertex, mut time) }
		}
		mut bridge_count := 0
		for left in 0 .. vertex_count {
			for right in left + 1 .. vertex_count {
				if state.bridge_mask[left] & (u64(1) << right) != 0 { bridge_count++ }
			}
		}
		output_length := 2 * bridge_count
		if output_capacity < usize(output_length) { return -2 }
		mut position := 0
		for left in 0 .. vertex_count {
			for right in left + 1 .. vertex_count {
				if state.bridge_mask[left] & (u64(1) << right) != 0 {
					output[position] = u8(left)
					output[position + 1] = u8(right)
					position += 2
				}
			}
		}
		return i64(output_length)
	}
}
