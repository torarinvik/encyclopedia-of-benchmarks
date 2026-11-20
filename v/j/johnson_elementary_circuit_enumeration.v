module johnson_elementary_circuit_enumeration

const max_vertices = 8
const max_edges = 24
const max_input_length = 51
const count_scale = i64(1_000_000_000_000)

struct SccState {
mut:
	graph [max_vertices * max_vertices]bool
	n int
	lower_bound int
	next_index int
	component_count int
	stack_length int
	index [max_vertices]int
	low_link [max_vertices]int
	component_id [max_vertices]int
	on_stack [max_vertices]bool
	stack [max_vertices]int
	component_size [max_vertices]int
	component_minimum [max_vertices]int
}

struct SccSelection {
	mut:
	start int
	component int
	component_id [max_vertices]int
}

struct CircuitState {
mut:
	graph [max_vertices * max_vertices]bool
	n int
	start int
	selected_component int
	depth int
	component_id [max_vertices]int
	blocked [max_vertices]bool
	dependencies [max_vertices * max_vertices]bool
	path [max_vertices]int
	count i64
	code_sum i64
}

fn strong_connect(vertex int, mut state &SccState) {
	state.index[vertex] = state.next_index
	state.low_link[vertex] = state.next_index
	state.next_index++
	state.stack[state.stack_length] = vertex
	state.stack_length++
	state.on_stack[vertex] = true
	for neighbor in state.lower_bound .. state.n {
		if !state.graph[vertex * max_vertices + neighbor] { continue }
		if state.index[neighbor] < 0 {
			strong_connect(neighbor, mut state)
			state.low_link[vertex] = min(state.low_link[vertex], state.low_link[neighbor])
		} else if state.on_stack[neighbor] {
			state.low_link[vertex] = min(state.low_link[vertex], state.index[neighbor])
		}
	}
	if state.low_link[vertex] == state.index[vertex] {
		component := state.component_count
		mut size := 0
		mut minimum := state.n
		for {
			state.stack_length--
			member := state.stack[state.stack_length]
			state.on_stack[member] = false
			state.component_id[member] = component
			size++
			minimum = min(minimum, member)
			if member == vertex { break }
		}
		state.component_size[component] = size
		state.component_minimum[component] = minimum
		state.component_count++
	}
}

fn find_selected_component(n int, lower_bound int, graph [max_vertices * max_vertices]bool) SccSelection {
	mut state := SccState{graph: graph, n: n, lower_bound: lower_bound}
	for vertex in 0 .. max_vertices {
		state.index[vertex] = -1
		state.low_link[vertex] = -1
		state.component_id[vertex] = -1
	}
	for vertex in lower_bound .. n {
		if state.index[vertex] < 0 { strong_connect(vertex, mut state) }
	}
	mut result := SccSelection{start: n, component: -1}
	result.component_id = state.component_id
	for component in 0 .. state.component_count {
		if state.component_size[component] > 1 && state.component_minimum[component] < result.start {
			result.start = state.component_minimum[component]
			result.component = component
		}
	}
	return result
}

fn unblock(vertex int, mut state &CircuitState) {
	if !state.blocked[vertex] { return }
	state.blocked[vertex] = false
	for dependent in 0 .. state.n {
		slot := vertex * max_vertices + dependent
		if state.dependencies[slot] {
			state.dependencies[slot] = false
			if state.blocked[dependent] { unblock(dependent, mut state) }
		}
	}
}

fn record_cycle(mut state &CircuitState) {
	mut code := i64(0)
	mut place := i64(1)
	for index in 0 .. state.depth {
		code += i64(state.path[index] + 1) * place
		place *= 9
	}
	state.count++
	state.code_sum += code
}

fn circuit(vertex int, mut state &CircuitState) bool {
	state.path[state.depth] = vertex
	state.depth++
	state.blocked[vertex] = true
	mut found := false
	for neighbor in 0 .. state.n {
		if !state.graph[vertex * max_vertices + neighbor]
			|| state.component_id[neighbor] != state.selected_component { continue }
		if neighbor == state.start {
			record_cycle(mut state)
			found = true
		} else if !state.blocked[neighbor] && circuit(neighbor, mut state) {
			found = true
		}
	}
	if found {
		unblock(vertex, mut state)
	} else {
		for neighbor in 0 .. state.n {
			if state.graph[vertex * max_vertices + neighbor]
				&& state.component_id[neighbor] == state.selected_component {
				state.dependencies[neighbor * max_vertices + vertex] = true
			}
		}
	}
	state.depth--
	return found
}

@[export: 'johnson_elementary_circuit_enumeration']
pub fn johnson_elementary_circuit_enumeration(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
		n, m := int(n_value), int(m_value)
		if length != usize(2 + 2 * m) { return -1 }
		mut graph := [max_vertices * max_vertices]bool{}
		for edge_index in 0 .. m {
			from_value, to_value := input[2 + 2 * edge_index], input[3 + 2 * edge_index]
			if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value
				|| from_value == to_value { return -1 }
			from_vertex, to_vertex := int(from_value), int(to_value)
			slot := from_vertex * max_vertices + to_vertex
			if graph[slot] { return -1 }
			graph[slot] = true
		}

		mut lower_bound := 0
		mut total_count := i64(0)
		mut total_code_sum := i64(0)
		for lower_bound < n {
			selection := find_selected_component(n, lower_bound, graph)
			if selection.component < 0 { break }
			mut state := CircuitState{
				graph: graph
				n: n
				start: selection.start
				selected_component: selection.component
				component_id: selection.component_id
			}
			_ = circuit(state.start, mut state)
			total_count += state.count
			total_code_sum += state.code_sum
			lower_bound = selection.start + 1
		}
		return total_count * count_scale + total_code_sum
	}
}
