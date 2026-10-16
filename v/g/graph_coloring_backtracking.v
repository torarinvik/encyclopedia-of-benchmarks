fn color_vertex(vertex int, count int, adjacency []bool, mut colors []i64) bool {
	if vertex == count { return true }
	for color in 1 .. count + 1 {
		mut safe := true
		for neighbor in 0 .. count {
			if adjacency[vertex * 64 + neighbor] && colors[neighbor] == i64(color) {
				safe = false
				break
			}
		}
		if !safe { continue }
		colors[vertex] = i64(color)
		if color_vertex(vertex + 1, count, adjacency, mut colors) { return true }
		colors[vertex] = 0
	}
	return false
}

fn put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'graph_coloring_backtracking']
pub fn graph_coloring_backtracking(input &i64, length usize, mut output &u8, capacity usize) i64 {
	max_vertices := 64
	max_edges := 2016
	if length < 2 || isnil(input) { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 0 || n_value > max_vertices || m_value < 0 || m_value > max_edges ||
		length != usize(2 + 2 * m_value) { return -1 }
	n := int(n_value)
	m := int(m_value)
	mut adjacency := []bool{len: 64 * 64, init: false}
	for edge in 0 .. m {
		u_value := unsafe { input[2 + 2 * edge] }
		v_value := unsafe { input[3 + 2 * edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		adjacency[u * 64 + v] = true
		adjacency[v * 64 + u] = true
	}
	mut colors := []i64{len: 64, init: 0}
	if !color_vertex(0, n, adjacency, mut colors) { return -1 }
	mut colors_used := i64(0)
	for vertex in 0 .. n { if colors[vertex] > colors_used { colors_used = colors[vertex] } }
	mut packed := []i64{len: n + 2, init: 0}
	packed[0] = n_value
	for vertex in 0 .. n { packed[vertex + 1] = colors[vertex] }
	packed[n + 1] = colors_used
	required := usize((n + 2) * 8)
	if capacity < required || isnil(output) { return -2 }
	for index in 0 .. n + 2 { put_i64(mut output, index * 8, packed[index]) }
	return i64(required)
}
