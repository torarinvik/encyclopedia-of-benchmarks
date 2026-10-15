module tarjan_scc

const max_vertex_count = 40
const max_edge_count = 2047
const max_input_length = 2 + 2 * max_edge_count

struct GraphState {
	mut:
	adjacency [max_vertex_count]u64
	on_stack [max_vertex_count]bool
	stack [max_vertex_count]int
	stack_length int
	discovery [max_vertex_count]int
	low [max_vertex_count]int
	component_id [max_vertex_count]int
	time int
	component_count int
}

fn visit_vertex(mut state GraphState, vertex_count int, vertex int) {
	state.discovery[vertex] = state.time
	state.low[vertex] = state.time
	state.time++
	state.on_stack[vertex] = true
	state.stack[state.stack_length] = vertex
	state.stack_length++
	for neighbor in 0 .. vertex_count {
		if state.adjacency[vertex] & (u64(1) << neighbor) == 0 { continue }
		if state.discovery[neighbor] == -1 {
			visit_vertex(mut state, vertex_count, neighbor)
			if state.low[neighbor] < state.low[vertex] { state.low[vertex] = state.low[neighbor] }
		} else if state.on_stack[neighbor] && state.discovery[neighbor] < state.low[vertex] {
			state.low[vertex] = state.discovery[neighbor]
		}
	}
	if state.low[vertex] == state.discovery[vertex] {
		for {
			state.stack_length--
			member := state.stack[state.stack_length]
			state.on_stack[member] = false
			state.component_id[member] = state.component_count
			if member == vertex { break }
		}
		state.component_count++
	}
}

@[export: 'tarjan_scc']
pub fn tarjan_scc(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_vertex_count || input[1] < 0 || input[1] > max_edge_count { return -1 }
		vertex_count := int(input[0])
		edge_count := int(input[1])
		if int(length) != 2 + 2 * edge_count { return -1 }
		mut state := GraphState{}
		for vertex in 0 .. max_vertex_count {
			state.discovery[vertex] = -1
			state.component_id[vertex] = -1
		}
		for edge in 0 .. edge_count {
			from_value := input[2 + 2 * edge]
			to_value := input[3 + 2 * edge]
			if from_value < 0 || to_value < 0 || from_value >= i64(vertex_count) || to_value >= i64(vertex_count) { return -1 }
			state.adjacency[int(from_value)] |= u64(1) << int(to_value)
		}
		for vertex in 0 .. vertex_count {
			if state.discovery[vertex] == -1 { visit_vertex(mut state, vertex_count, vertex) }
		}
		output_length := 1 + vertex_count + state.component_count
		if output_capacity < usize(output_length) { return -2 }
		output[0] = u8(state.component_count)
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
