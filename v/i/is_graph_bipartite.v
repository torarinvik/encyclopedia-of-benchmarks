module is_graph_bipartite

const max_vertices = 64
const max_edges = 256
const max_input_length = 2 + 2 * max_edges

@[export: 'is_graph_bipartite']
pub fn is_graph_bipartite(values &i64, length usize) i64 {
	if values == nil || length < 2 || length > max_input_length { return -1 }
	vertex_count_raw := unsafe { values[0] }
	edge_count_raw := unsafe { values[1] }
	if vertex_count_raw < 0 || vertex_count_raw > max_vertices || edge_count_raw < 0 || edge_count_raw > max_edges {
		return -1
	}
	vertex_count := int(vertex_count_raw)
	edge_count := int(edge_count_raw)
	if length != usize(2 + 2 * edge_count) { return -1 }

	mut head := [max_vertices]int{}
	mut arc_to := [2 * max_edges]int{}
	mut arc_next := [2 * max_edges]int{}
	mut side := [max_vertices]int{}
	mut queue := [max_vertices]int{}
	for vertex in 0 .. vertex_count {
		head[vertex] = -1
		side[vertex] = -1
	}
	mut arc_count := 0
	unsafe {
		for edge in 0 .. edge_count {
			u_raw := values[2 + 2 * edge]
			v_raw := values[3 + 2 * edge]
			if u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw { return -1 }
			u := int(u_raw - 1)
			v := int(v_raw - 1)
			arc_to[arc_count] = v
			arc_next[arc_count] = head[u]
			head[u] = arc_count
			arc_count++
			arc_to[arc_count] = u
			arc_next[arc_count] = head[v]
			head[v] = arc_count
			arc_count++
		}
	}

	mut bipartite := true
	for start in 0 .. vertex_count {
		if side[start] != -1 { continue }
		mut queue_head := 0
		mut queue_tail := 1
		queue[0] = start
		side[start] = 0
		for queue_head < queue_tail {
			current := queue[queue_head]
			queue_head++
			mut arc := head[current]
			for arc != -1 {
				neighbor := arc_to[arc]
				if side[neighbor] == -1 {
					side[neighbor] = side[current] ^ 1
					queue[queue_tail] = neighbor
					queue_tail++
				} else if side[neighbor] == side[current] {
					bipartite = false
				}
				arc = arc_next[arc]
			}
		}
	}
	return if bipartite { 1 } else { 0 }
}
