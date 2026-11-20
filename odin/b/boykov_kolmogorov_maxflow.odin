package boykov_kolmogorov_maxflow

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 16
MAX_INPUT_LENGTH :: c.size_t(4 + 3 * MAX_EDGES + 1)

FREE_TREE :: 0
SOURCE_TREE :: 1
SINK_TREE :: 2

Flow_State :: struct {
	n: int,
	source: int,
	sink: int,
	residual: [MAX_VERTICES][MAX_VERTICES]i64,
	tree: [MAX_VERTICES]int,
	parent: [MAX_VERTICES]int,
	active_queue: [MAX_VERTICES]int,
	active_head: int,
	active_tail: int,
	active_count: int,
	is_active: [MAX_VERTICES]bool,
	orphan_queue: [MAX_VERTICES]int,
	orphan_head: int,
	orphan_tail: int,
	orphan_count: int,
	is_orphan: [MAX_VERTICES]bool,
	total_flow: i64,
}

tree_capacity :: proc(state: ^Flow_State, kind, parent_vertex, child_vertex: int) -> i64 {
	if kind == SOURCE_TREE {
		return state.residual[parent_vertex][child_vertex]
	}
	return state.residual[child_vertex][parent_vertex]
}

enqueue_active :: proc(state: ^Flow_State, vertex: int) {
	if state.is_active[vertex] { return }
	if state.active_tail >= MAX_VERTICES {
		for offset in 0..<state.active_count {
			state.active_queue[offset] = state.active_queue[state.active_head + offset]
		}
		state.active_head = 0
		state.active_tail = state.active_count
	}
	state.active_queue[state.active_tail] = vertex
	state.active_tail += 1
	state.active_count += 1
	state.is_active[vertex] = true
}

dequeue_active :: proc(state: ^Flow_State) -> int {
	vertex := state.active_queue[state.active_head]
	state.active_head += 1
	state.active_count -= 1
	state.is_active[vertex] = false
	if state.active_count == 0 {
		state.active_head = 0
		state.active_tail = 0
	}
	return vertex
}

remove_active :: proc(state: ^Flow_State, vertex: int) {
	if !state.is_active[vertex] { return }
	index := state.active_head
	for index < state.active_tail {
		if state.active_queue[index] == vertex {
			shift := index
			for shift + 1 < state.active_tail {
				state.active_queue[shift] = state.active_queue[shift + 1]
				shift += 1
			}
			state.active_tail -= 1
			state.active_count -= 1
			state.is_active[vertex] = false
			if state.active_count == 0 {
				state.active_head = 0
				state.active_tail = 0
			}
			return
		}
		index += 1
	}
}

enqueue_orphan :: proc(state: ^Flow_State, vertex: int) {
	if state.is_orphan[vertex] { return }
	if state.orphan_tail >= MAX_VERTICES {
		for offset in 0..<state.orphan_count {
			state.orphan_queue[offset] = state.orphan_queue[state.orphan_head + offset]
		}
		state.orphan_head = 0
		state.orphan_tail = state.orphan_count
	}
	state.orphan_queue[state.orphan_tail] = vertex
	state.orphan_tail += 1
	state.orphan_count += 1
	state.is_orphan[vertex] = true
}

dequeue_orphan :: proc(state: ^Flow_State) -> int {
	vertex := state.orphan_queue[state.orphan_head]
	state.orphan_head += 1
	state.orphan_count -= 1
	state.is_orphan[vertex] = false
	if state.orphan_count == 0 {
		state.orphan_head = 0
		state.orphan_tail = 0
	}
	return vertex
}

has_terminal_origin :: proc(state: ^Flow_State, vertex, kind, blocked: int) -> bool {
	root := state.source
	if kind == SINK_TREE { root = state.sink }
	seen: [MAX_VERTICES]bool
	current := vertex
	for {
		if current == blocked || current < 0 || current >= state.n || seen[current] || state.tree[current] != kind {
			return false
		}
		if current == root { return true }
		seen[current] = true
		next_vertex := state.parent[current]
		if next_vertex < 0 || next_vertex >= state.n { return false }
		if tree_capacity(state, kind, next_vertex, current) <= 0 { return false }
		current = next_vertex
	}
}

solve :: proc(input: [^]i64, n, edge_count, source, sink: int) -> i64 {
	state := Flow_State{n = n, source = source, sink = sink, total_flow = 0}
	for vertex in 0..<n { state.parent[vertex] = -1 }
	for edge_index in 0..<edge_count {
		from_vertex := int(input[4 + 3 * edge_index])
		to_vertex := int(input[5 + 3 * edge_index])
		capacity := input[6 + 3 * edge_index]
		state.residual[from_vertex][to_vertex] += capacity
	}
	state.tree[source] = SOURCE_TREE
	state.tree[sink] = SINK_TREE
	enqueue_active(&state, source)
	enqueue_active(&state, sink)

	for state.active_count > 0 {
		bridge_source, bridge_sink := -1, -1
		found_bridge := false
		for state.active_count > 0 && !found_bridge {
			vertex := dequeue_active(&state)
			kind := state.tree[vertex]
			for neighbor in 0..<n {
				if tree_capacity(&state, kind, vertex, neighbor) <= 0 { continue }
				if state.tree[neighbor] == FREE_TREE {
					state.tree[neighbor] = kind
					state.parent[neighbor] = vertex
					enqueue_active(&state, neighbor)
				} else if state.tree[neighbor] != kind {
					if kind == SOURCE_TREE {
						bridge_source, bridge_sink = vertex, neighbor
					} else {
						bridge_source, bridge_sink = neighbor, vertex
					}
					enqueue_active(&state, vertex)
					found_bridge = true
					break
				}
			}
		}
		if !found_bridge { break }

		path_from: [MAX_VERTICES]int
		path_to: [MAX_VERTICES]int
		path_length := 0
		reversed_source: [MAX_VERTICES]int
		source_length := 0
		current := bridge_source
		for current != source {
			if current < 0 || current >= n || source_length >= MAX_VERTICES { return -1 }
			reversed_source[source_length] = current
			source_length += 1
			current = state.parent[current]
		}
		source_index := source_length
		for source_index > 0 {
			source_index -= 1
			child := reversed_source[source_index]
			path_from[path_length] = state.parent[child]
			path_to[path_length] = child
			path_length += 1
		}
		path_from[path_length] = bridge_source
		path_to[path_length] = bridge_sink
		path_length += 1
		current = bridge_sink
		for current != sink {
			if current < 0 || current >= n || path_length >= MAX_VERTICES { return -1 }
			next_vertex := state.parent[current]
			if next_vertex < 0 || next_vertex >= n { return -1 }
			path_from[path_length] = current
			path_to[path_length] = next_vertex
			path_length += 1
			current = next_vertex
		}
		if path_length == 0 { return -1 }

		bottleneck := state.residual[path_from[0]][path_to[0]]
		for path_index in 1..<path_length {
			bottleneck = min(bottleneck, state.residual[path_from[path_index]][path_to[path_index]])
		}
		if bottleneck <= 0 { return -1 }
		for path_index in 0..<path_length {
			from_vertex, to_vertex := path_from[path_index], path_to[path_index]
			state.residual[from_vertex][to_vertex] -= bottleneck
			state.residual[to_vertex][from_vertex] += bottleneck
		}
		state.total_flow += bottleneck

		for path_index in 0..<path_length {
			from_vertex, to_vertex := path_from[path_index], path_to[path_index]
			if state.residual[from_vertex][to_vertex] != 0 { continue }
			if state.tree[from_vertex] == SOURCE_TREE && state.tree[to_vertex] == SOURCE_TREE && state.parent[to_vertex] == from_vertex {
				state.parent[to_vertex] = -1
				enqueue_orphan(&state, to_vertex)
			} else if state.tree[from_vertex] == SINK_TREE && state.tree[to_vertex] == SINK_TREE && state.parent[from_vertex] == to_vertex {
				state.parent[from_vertex] = -1
				enqueue_orphan(&state, from_vertex)
			}
		}

		for state.orphan_count > 0 {
			orphan := dequeue_orphan(&state)
			kind := state.tree[orphan]
			if kind == FREE_TREE { continue }
			replacement := -1
			for candidate in 0..<n {
				if candidate == orphan || state.tree[candidate] != kind { continue }
				if tree_capacity(&state, kind, candidate, orphan) <= 0 { continue }
				if has_terminal_origin(&state, candidate, kind, orphan) {
					replacement = candidate
					break
				}
			}
			if replacement >= 0 {
				state.parent[orphan] = replacement
				continue
			}
			for neighbor in 0..<n {
				if state.tree[neighbor] != kind { continue }
				if tree_capacity(&state, kind, neighbor, orphan) > 0 { enqueue_active(&state, neighbor) }
				if state.parent[neighbor] == orphan {
					state.parent[neighbor] = -1
					enqueue_orphan(&state, neighbor)
				}
			}
			state.tree[orphan] = FREE_TREE
			state.parent[orphan] = -1
			remove_active(&state, orphan)
		}
	}
	return state.total_flow
}

@(export)
boykov_kolmogorov_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	n_value, m_value, source_value, sink_value := input[0], input[1], input[2], input[3]
	if n_value < 2 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES do return -1
	n, edge_count := int(n_value), int(m_value)
	if length != c.size_t(4 + 3 * edge_count) || source_value < 0 || source_value >= n_value ||
		sink_value < 0 || sink_value >= n_value || source_value == sink_value do return -1
	for edge_index in 0..<edge_count {
		from_value, to_value, capacity := input[4 + 3 * edge_index], input[5 + 3 * edge_index], input[6 + 3 * edge_index]
		if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value ||
			from_value == to_value || capacity < 0 || capacity > 15 do return -1
	}
	return solve(input, n, edge_count, int(source_value), int(sink_value))
}
