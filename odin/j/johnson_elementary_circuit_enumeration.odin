package johnson_elementary_circuit_enumeration

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 24
MAX_INPUT_LENGTH :: 51
COUNT_SCALE :: i64(1_000_000_000_000)

Graph :: [MAX_VERTICES][MAX_VERTICES]bool

SCC_State :: struct {
	graph: Graph,
	n, lower_bound: int,
	next_index, component_count, stack_length: int,
	index, low_link, component_id: [MAX_VERTICES]int,
	on_stack: [MAX_VERTICES]bool,
	stack: [MAX_VERTICES]int,
	component_size, component_minimum: [MAX_VERTICES]int,
}

Circuit_State :: struct {
	graph: Graph,
	n, start, selected_component, depth: int,
	component_id: [MAX_VERTICES]int,
	blocked: [MAX_VERTICES]bool,
	dependencies: [MAX_VERTICES * MAX_VERTICES]bool,
	path: [MAX_VERTICES]int,
	count, code_sum: i64,
}

strong_connect :: proc(vertex: int, state: ^SCC_State) {
	state.index[vertex] = state.next_index
	state.low_link[vertex] = state.next_index
	state.next_index += 1
	state.stack[state.stack_length] = vertex
	state.stack_length += 1
	state.on_stack[vertex] = true
	for neighbor := state.lower_bound; neighbor < state.n; neighbor += 1 {
		if !state.graph[vertex][neighbor] do continue
		if state.index[neighbor] < 0 {
			strong_connect(neighbor, state)
			state.low_link[vertex] = min(state.low_link[vertex], state.low_link[neighbor])
		} else if state.on_stack[neighbor] {
			state.low_link[vertex] = min(state.low_link[vertex], state.index[neighbor])
		}
	}
	if state.low_link[vertex] == state.index[vertex] {
		component := state.component_count
		size := 0
		minimum := state.n
		for {
			state.stack_length -= 1
			member := state.stack[state.stack_length]
			state.on_stack[member] = false
			state.component_id[member] = component
			size += 1
			minimum = min(minimum, member)
			if member == vertex do break
		}
		state.component_size[component] = size
		state.component_minimum[component] = minimum
		state.component_count += 1
	}
}

find_selected_component :: proc(n, lower_bound: int, graph: Graph,
		component_id: ^[MAX_VERTICES]int) -> (int, int) {
	state := SCC_State{graph = graph, n = n, lower_bound = lower_bound}
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 {
		state.index[vertex] = -1
		state.low_link[vertex] = -1
		state.component_id[vertex] = -1
	}
	for vertex := lower_bound; vertex < n; vertex += 1 {
		if state.index[vertex] < 0 do strong_connect(vertex, &state)
	}
	for vertex := 0; vertex < n; vertex += 1 do component_id[vertex] = state.component_id[vertex]
	start := n
	selected_component := -1
	for component := 0; component < state.component_count; component += 1 {
		if state.component_size[component] > 1 && state.component_minimum[component] < start {
			start = state.component_minimum[component]
			selected_component = component
		}
	}
	return start, selected_component
}

unblock :: proc(vertex: int, state: ^Circuit_State) {
	if !state.blocked[vertex] do return
	state.blocked[vertex] = false
	for dependent := 0; dependent < state.n; dependent += 1 {
		slot := vertex*MAX_VERTICES + dependent
		if state.dependencies[slot] {
			state.dependencies[slot] = false
			if state.blocked[dependent] do unblock(dependent, state)
		}
	}
}

record_cycle :: proc(state: ^Circuit_State) {
	code, place := i64(0), i64(1)
	for index := 0; index < state.depth; index += 1 {
		code += i64(state.path[index] + 1) * place
		place *= 9
	}
	state.count += 1
	state.code_sum += code
}

circuit :: proc(vertex: int, state: ^Circuit_State) -> bool {
	state.path[state.depth] = vertex
	state.depth += 1
	state.blocked[vertex] = true
	found := false
	for neighbor := 0; neighbor < state.n; neighbor += 1 {
		if !state.graph[vertex][neighbor] || state.component_id[neighbor] != state.selected_component do continue
		if neighbor == state.start {
			record_cycle(state)
			found = true
		} else if !state.blocked[neighbor] && circuit(neighbor, state) {
			found = true
		}
	}
	if found {
		unblock(vertex, state)
	} else {
		for neighbor := 0; neighbor < state.n; neighbor += 1 {
			if state.graph[vertex][neighbor] && state.component_id[neighbor] == state.selected_component {
				state.dependencies[neighbor*MAX_VERTICES+vertex] = true
			}
		}
	}
	state.depth -= 1
	return found
}

@(export)
johnson_elementary_circuit_enumeration :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES do return -1
	n, m := int(n_value), int(m_value)
	if int(length) != 2+2*m do return -1
	var graph: Graph
	for edge_index := 0; edge_index < m; edge_index += 1 {
		from_value, to_value := input[2+2*edge_index], input[3+2*edge_index]
		if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value || from_value == to_value do return -1
		from_vertex, to_vertex := int(from_value), int(to_value)
		if graph[from_vertex][to_vertex] do return -1
		graph[from_vertex][to_vertex] = true
	}

	lower_bound := 0
	total_count := i64(0)
	total_code_sum := i64(0)
	for lower_bound < n {
		var component_id: [MAX_VERTICES]int
		for vertex := 0; vertex < MAX_VERTICES; vertex += 1 do component_id[vertex] = -1
		start, selected_component := find_selected_component(n, lower_bound, graph, &component_id)
		if selected_component < 0 do break
		state := Circuit_State{graph = graph, n = n, start = start,
			selected_component = selected_component, component_id = component_id}
		_ = circuit(start, &state)
		total_count += state.count
		total_code_sum += state.code_sum
		lower_bound = start + 1
	}
	return total_count*COUNT_SCALE + total_code_sum
}
