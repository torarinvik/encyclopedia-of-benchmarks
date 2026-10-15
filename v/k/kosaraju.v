module kosaraju

const max_vertex_count = 40
const max_edge_count = 2047
const max_input_length = 2 + 2 * max_edge_count

struct GraphState {
	mut:
	adjacency [max_vertex_count]u64
	transpose [max_vertex_count]u64
	visited [max_vertex_count]bool
	order [max_vertex_count]int
	order_length int
	component_id [max_vertex_count]int
}

fn fill_order(mut state GraphState, vertex_count int, vertex int) {
	state.visited[vertex] = true
	for neighbor in 0 .. vertex_count {
		if state.adjacency[vertex] & (u64(1) << neighbor) != 0 && !state.visited[neighbor] {
			fill_order(mut state, vertex_count, neighbor)
		}
	}
	state.order[state.order_length] = vertex
	state.order_length++
}

fn collect_component(mut state GraphState, vertex_count int, vertex int, id int) {
	state.visited[vertex] = true
	state.component_id[vertex] = id
	for neighbor in 0 .. vertex_count {
		if state.transpose[vertex] & (u64(1) << neighbor) != 0 && !state.visited[neighbor] {
			collect_component(mut state, vertex_count, neighbor, id)
		}
	}
}

@[export: 'kosaraju']
pub fn kosaraju(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_vertex_count || input[1] < 0 || input[1] > max_edge_count { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if int(length) != 2 + 2 * edge_count { return -1 }
		mut state := GraphState{}
		for edge in 0 .. edge_count {
			from_value := input[2 + 2 * edge]
			to_value := input[3 + 2 * edge]
			if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) || to_value >= i64(vertex_count) { return -1 }
			from := int(from_value)
			to := int(to_value)
			state.adjacency[from] |= u64(1) << to
			state.transpose[to] |= u64(1) << from
		}
		for vertex in 0 .. max_vertex_count { state.component_id[vertex] = -1 }
		for vertex in 0 .. vertex_count {
			if !state.visited[vertex] { fill_order(mut state, vertex_count, vertex) }
		}
		for vertex in 0 .. max_vertex_count { state.visited[vertex] = false }
		mut component_count := 0
		for index := state.order_length; index > 0; index-- {
			vertex := state.order[index - 1]
			if !state.visited[vertex] {
				collect_component(mut state, vertex_count, vertex, component_count)
				component_count++
			}
		}
		output_length := 1 + vertex_count + component_count
		if output_capacity < usize(output_length) { return -2 }
		output[0] = u8(component_count)
		mut position := 1
		for first in 0 .. vertex_count {
			id := state.component_id[first]
			mut emitted := false
			for earlier in 0 .. first {
				if state.component_id[earlier] == id { emitted = true }
			}
			if emitted { continue }
			mut component_size := 0
			for member in first .. vertex_count {
				if state.component_id[member] == id { component_size++ }
			}
			output[position] = u8(component_size)
			position++
			for member in first .. vertex_count {
				if state.component_id[member] == id {
					output[position] = u8(member)
					position++
				}
			}
		}
		return i64(output_length)
	}
}
