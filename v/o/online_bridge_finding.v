module online_bridge_finding

const max_vertices = 64
const max_edges = 128
const max_input_length = 2 + 2 * max_edges + 1

struct BridgeState {
mut:
	dsu_2ecc [max_vertices]int
	dsu_cc [max_vertices]int
	dsu_cc_size [max_vertices]int
	parent [max_vertices]int
	last_visit [max_vertices]int
	iteration int
	bridges int
}

fn find_2ecc(mut state BridgeState, vertex int) int {
	if vertex == -1 { return -1 }
	if state.dsu_2ecc[vertex] == vertex { return vertex }
	state.dsu_2ecc[vertex] = find_2ecc(mut state, state.dsu_2ecc[vertex])
	return state.dsu_2ecc[vertex]
}

fn find_cc(mut state BridgeState, vertex_input int) int {
	vertex := find_2ecc(mut state, vertex_input)
	if state.dsu_cc[vertex] == vertex { return vertex }
	state.dsu_cc[vertex] = find_cc(mut state, state.dsu_cc[vertex])
	return state.dsu_cc[vertex]
}

fn make_root(mut state BridgeState, vertex_input int) {
	root := find_2ecc(mut state, vertex_input)
	mut vertex := root
	mut child := -1
	for vertex != -1 {
		next := find_2ecc(mut state, state.parent[vertex])
		state.parent[vertex] = child
		state.dsu_cc[vertex] = root
		child = vertex
		vertex = next
	}
	state.dsu_cc_size[root] = state.dsu_cc_size[child]
}

fn merge_path(mut state BridgeState, left_input int, right_input int) {
	state.iteration++
	mut path_left := [max_vertices]int{}
	mut path_right := [max_vertices]int{}
	mut left_length := 0
	mut right_length := 0
	mut left := left_input
	mut right := right_input
	mut lca := -1
	for lca == -1 {
		if left != -1 {
			left = find_2ecc(mut state, left)
			path_left[left_length] = left
			left_length++
			if state.last_visit[left] == state.iteration { lca = left; break }
			state.last_visit[left] = state.iteration
			left = state.parent[left]
		}
		if right != -1 {
			right = find_2ecc(mut state, right)
			path_right[right_length] = right
			right_length++
			if state.last_visit[right] == state.iteration { lca = right; break }
			state.last_visit[right] = state.iteration
			right = state.parent[right]
		}
	}
	for index in 0 .. left_length {
		vertex := path_left[index]
		state.dsu_2ecc[vertex] = lca
		if vertex == lca { break }
		state.bridges--
	}
	for index in 0 .. right_length {
		vertex := path_right[index]
		state.dsu_2ecc[vertex] = lca
		if vertex == lca { break }
		state.bridges--
	}
}

fn add_edge(mut state BridgeState, left_input int, right_input int) {
	mut left := find_2ecc(mut state, left_input)
	mut right := find_2ecc(mut state, right_input)
	if left == right { return }
	mut left_cc := find_cc(mut state, left)
	mut right_cc := find_cc(mut state, right)
	if left_cc != right_cc {
		state.bridges++
		if state.dsu_cc_size[left_cc] > state.dsu_cc_size[right_cc] {
			left, right = right, left
			left_cc, right_cc = right_cc, left_cc
		}
		make_root(mut state, left)
		state.parent[left] = right
		state.dsu_cc[left] = right
		state.dsu_cc_size[right_cc] += state.dsu_cc_size[left]
	} else {
		merge_path(mut state, left, right)
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'online_bridge_finding']
pub fn online_bridge_finding(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		raw_vertices, raw_edges := values[0], values[1]
		if raw_vertices < 1 || raw_vertices > max_vertices || raw_edges < 0 || raw_edges > max_edges { return -1 }
		vertex_count, edge_count := int(raw_vertices), int(raw_edges)
		if length != usize(2 + 2 * edge_count) { return -1 }
		for edge in 0 .. edge_count {
			left, right := values[2 + 2 * edge], values[3 + 2 * edge]
			if left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices { return -1 }
		}
		output_bytes := edge_count * 8
		if output_bytes > 0 && (output == nil || output_capacity < output_bytes) { return -2 }
		mut state := BridgeState{}
		for vertex in 0 .. vertex_count {
			state.dsu_2ecc[vertex] = vertex
			state.dsu_cc[vertex] = vertex
			state.dsu_cc_size[vertex] = 1
			state.parent[vertex] = -1
		}
		for edge in 0 .. edge_count {
			add_edge(mut state, int(values[2 + 2 * edge]), int(values[3 + 2 * edge]))
			store_i64_le(mut output, edge * 8, i64(state.bridges))
		}
		return i64(output_bytes)
	}
}
