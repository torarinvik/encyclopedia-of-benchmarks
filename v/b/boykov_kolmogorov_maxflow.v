module boykov_kolmogorov_maxflow

const max_vertices = 8
const max_input_length = 53
const free_tree = 0
const source_tree = 1
const sink_tree = 2

struct BkState {
mut:
	n int
	source int
	sink int
	total_flow i64
	residual [max_vertices * max_vertices]i64
	tree [max_vertices]int
	parent [max_vertices]int
	active_queue [max_vertices]int
	active_count int
	is_active [max_vertices]bool
}

fn bk_capacity(state &BkState, kind int, parent int, child int) i64 {
	if kind == source_tree { return state.residual[parent * max_vertices + child] }
	return state.residual[child * max_vertices + parent]
}

fn bk_has_terminal_origin(state &BkState, candidate int, blocked int,
	kind int, root int, n int) bool {
	mut seen := [max_vertices]bool{}
	mut current := candidate
	for {
		if current == blocked || current < 0 || current >= n || state.tree[current] != kind { return false }
		if current == root { return true }
		if seen[current] { return false }
		seen[current] = true
		previous := state.parent[current]
		if previous < 0 || previous >= n || bk_capacity(state, kind, previous, current) <= 0 { return false }
		current = previous
	}
	return false
}

fn bk_activate(mut state &BkState, vertex int) {
	if state.is_active[vertex] { return }
	state.active_queue[state.active_count] = vertex
	state.active_count++
	state.is_active[vertex] = true
}

fn bk_remove_active(mut state &BkState, vertex int) {
	if !state.is_active[vertex] { return }
	mut kept := [max_vertices]int{}
	mut kept_count := 0
	for index in 0 .. state.active_count {
		queued := state.active_queue[index]
		if queued != vertex { kept[kept_count] = queued; kept_count++ }
	}
	for index in 0 .. kept_count { state.active_queue[index] = kept[index] }
	state.active_count = kept_count
	state.is_active[vertex] = false
}

fn solve(n int, m int, source int, sink int, input &i64) i64 {
	mut state := BkState{n: n, source: source, sink: sink}
	for vertex in 0 .. max_vertices { state.parent[vertex] = -1 }
	unsafe {
		for edge_index in 0 .. m {
			u_value := input[4 + 3 * edge_index]
			v_value := input[5 + 3 * edge_index]
			capacity := input[6 + 3 * edge_index]
			if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value || capacity < 0 || capacity > 15 { return -1 }
			u, v := int(u_value), int(v_value)
			state.residual[u * max_vertices + v] += capacity
		}
	}
	state.tree[source] = source_tree
	state.tree[sink] = sink_tree
	state.active_queue[0] = source
	state.active_queue[1] = sink
	state.active_count = 2
	state.is_active[source] = true
	state.is_active[sink] = true

	for state.active_count > 0 {
		mut bridge_source := -1
		mut bridge_sink := -1
		mut found_bridge := false
		for state.active_count > 0 && !found_bridge {
			vertex := state.active_queue[0]
			for shift_index in 1 .. state.active_count { state.active_queue[shift_index - 1] = state.active_queue[shift_index] }
			state.active_count--
			state.is_active[vertex] = false
			kind := state.tree[vertex]
			for neighbor in 0 .. n {
				if bk_capacity(state, kind, vertex, neighbor) <= 0 { continue }
				if state.tree[neighbor] == free_tree {
					state.tree[neighbor] = kind
					state.parent[neighbor] = vertex
					bk_activate(mut state, neighbor)
				} else if state.tree[neighbor] != kind {
					if kind == source_tree { bridge_source, bridge_sink = vertex, neighbor } else { bridge_source, bridge_sink = neighbor, vertex }
					bk_activate(mut state, vertex)
					found_bridge = true
					break
				}
			}
		}
		if !found_bridge { break }

		mut source_reverse := [max_vertices]int{}
		mut source_length := 0
		mut current := bridge_source
		for current != source {
			source_reverse[source_length] = current
			source_length++
			previous := state.parent[current]
			if previous < 0 || previous >= n { return -1 }
			current = previous
		}
		mut path_from := [max_vertices * 2]int{}
		mut path_to := [max_vertices * 2]int{}
		mut path_length := 0
		mut previous := source
		for source_length > 0 {
			source_length--
			next_vertex := source_reverse[source_length]
			path_from[path_length] = previous
			path_to[path_length] = next_vertex
			path_length++
			previous = next_vertex
		}
		path_from[path_length] = bridge_source
		path_to[path_length] = bridge_sink
		path_length++
		current = bridge_sink
		for current != sink {
			next_vertex := state.parent[current]
			if next_vertex < 0 || next_vertex >= n { return -1 }
			path_from[path_length] = current
			path_to[path_length] = next_vertex
			path_length++
			current = next_vertex
		}

		mut bottleneck := i64(240)
		for index in 0 .. path_length {
			capacity := state.residual[path_from[index] * max_vertices + path_to[index]]
			if capacity < bottleneck { bottleneck = capacity }
		}
		if bottleneck <= 0 { return -1 }
		for index in 0 .. path_length {
			from_vertex, to_vertex := path_from[index], path_to[index]
			state.residual[from_vertex * max_vertices + to_vertex] -= bottleneck
			state.residual[to_vertex * max_vertices + from_vertex] += bottleneck
		}
		state.total_flow += bottleneck

		mut orphan_queue := [max_vertices]int{}
		mut orphan_count := 0
		mut is_orphan := [max_vertices]bool{}
		for index in 0 .. path_length {
			from_vertex, to_vertex := path_from[index], path_to[index]
			if state.residual[from_vertex * max_vertices + to_vertex] != 0 { continue }
			if state.tree[from_vertex] == source_tree && state.tree[to_vertex] == source_tree && state.parent[to_vertex] == from_vertex {
				state.parent[to_vertex] = -1
				if !is_orphan[to_vertex] { orphan_queue[orphan_count] = to_vertex; orphan_count++; is_orphan[to_vertex] = true }
			} else if state.tree[from_vertex] == sink_tree && state.tree[to_vertex] == sink_tree && state.parent[from_vertex] == to_vertex {
				state.parent[from_vertex] = -1
				if !is_orphan[from_vertex] { orphan_queue[orphan_count] = from_vertex; orphan_count++; is_orphan[from_vertex] = true }
			}
		}

		for orphan_count > 0 {
			orphan := orphan_queue[0]
			for shift_index in 1 .. orphan_count { orphan_queue[shift_index - 1] = orphan_queue[shift_index] }
			orphan_count--
			is_orphan[orphan] = false
			kind := state.tree[orphan]
			if kind == free_tree { continue }
			mut replacement := -1
			root := if kind == source_tree { source } else { sink }
			for candidate in 0 .. n {
				if candidate != orphan && state.tree[candidate] == kind && bk_capacity(state, kind, candidate, orphan) > 0 && bk_has_terminal_origin(state, candidate, orphan, kind, root, n) {
					replacement = candidate
					break
				}
			}
			if replacement >= 0 { state.parent[orphan] = replacement; continue }
			for neighbor in 0 .. n {
				if state.tree[neighbor] != kind { continue }
				if bk_capacity(state, kind, neighbor, orphan) > 0 { bk_activate(mut state, neighbor) }
				if state.parent[neighbor] == orphan {
					state.parent[neighbor] = -1
					if !is_orphan[neighbor] { orphan_queue[orphan_count] = neighbor; orphan_count++; is_orphan[neighbor] = true }
				}
			}
			state.tree[orphan] = free_tree
			state.parent[orphan] = -1
			bk_remove_active(mut state, orphan)
		}
	}
	return state.total_flow
}

@[export: 'boykov_kolmogorov_maxflow']
pub fn boykov_kolmogorov_maxflow(input &i64, length usize) i64 {
	if input == nil || length < 4 || length > max_input_length { return -1 }
	unsafe {
		nv, mv, sv, tv := input[0], input[1], input[2], input[3]
		if nv < 2 || nv > max_vertices || mv < 0 || mv > 16 || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv { return -1 }
		if length != usize(4 + 3 * mv) { return -1 }
		return solve(int(nv), int(mv), int(sv), int(tv), input)
	}
}
