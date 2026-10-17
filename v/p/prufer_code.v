module prufer_code

const max_vertices = 64
const max_output_bytes = 1016

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn make_code(input &i64, n int, mut code []i64) int {
	mut adjacency := []bool{len: max_vertices * max_vertices, init: false}
	mut degree := []int{len: max_vertices, init: 0}
	for edge in 0 .. n - 1 {
		raw_u := unsafe { input[2 + edge * 2] }
		raw_v := unsafe { input[3 + edge * 2] }
		if raw_u < 0 || raw_v < 0 || raw_u >= i64(n) || raw_v >= i64(n) || raw_u == raw_v { return -1 }
		u := int(raw_u)
		v := int(raw_v)
		if adjacency[u * max_vertices + v] { return -1 }
		adjacency[u * max_vertices + v] = true
		adjacency[v * max_vertices + u] = true
		degree[u]++
		degree[v]++
	}
	mut visited := []bool{len: max_vertices, init: false}
	mut queue := []int{len: max_vertices, init: 0}
	mut head := 0
	mut tail := 1
	visited[0] = true
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			if adjacency[u * max_vertices + v] && !visited[v] {
				visited[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	if tail != n { return -1 }
	mut active := []bool{len: max_vertices, init: false}
	for v in 0 .. n { active[v] = true }
	mut code_length := 0
	for _ in 0 .. max(0, n - 2) {
		mut leaf := -1
		for v in 0 .. n {
			candidate := n - v - 1
			if active[candidate] && degree[candidate] == 1 { leaf = candidate; break }
		}
		if leaf < 0 { return -1 }
		mut neighbor := -1
		for v in 0 .. n {
			if active[v] && adjacency[leaf * max_vertices + v] { neighbor = v; break }
		}
		if neighbor < 0 { return -1 }
		code[code_length] = i64(neighbor)
		code_length++
		active[leaf] = false
		adjacency[leaf * max_vertices + neighbor] = false
		adjacency[neighbor * max_vertices + leaf] = false
		degree[neighbor]--
	}
	return code_length
}

fn add_edge(mut edges []i64, index int, u int, v int) {
	edges[index * 2] = i64(if u < v { u } else { v })
	edges[index * 2 + 1] = i64(if u < v { v } else { u })
}

fn make_decoded_edges(input &i64, n int, mut edges []i64) int {
	mut remaining := []int{len: max_vertices, init: 0}
	for i in 0 .. n - 2 {
		raw := unsafe { input[2 + i] }
		if raw < 0 || raw >= i64(n) { return -1 }
		remaining[int(raw)]++
	}
	mut active := []bool{len: max_vertices, init: false}
	for v in 0 .. n { active[v] = true }
	mut edge_count := 0
	for i in 0 .. n - 2 {
		mut leaf := -1
		for v in 0 .. n {
			candidate := n - v - 1
			if active[candidate] && remaining[candidate] == 0 { leaf = candidate; break }
		}
		if leaf < 0 { return -1 }
		vertex := int(unsafe { input[2 + i] })
		add_edge(mut edges, edge_count, leaf, vertex)
		edge_count++
		active[leaf] = false
		remaining[vertex]--
	}
	mut first := -1
	for v in 0 .. n { candidate := n - v - 1; if active[candidate] { first = candidate; break } }
	if first < 0 { return -1 }
	active[first] = false
	mut second := -1
	for v in 0 .. n { candidate := n - v - 1; if active[candidate] { second = candidate; break } }
	if second < 0 { return -1 }
	add_edge(mut edges, edge_count, first, second)
	edge_count++
	for i in 1 .. edge_count {
		u := edges[i * 2]
		v := edges[i * 2 + 1]
		mut j := i
		for j > 0 && (edges[(j - 1) * 2] > u || (edges[(j - 1) * 2] == u && edges[(j - 1) * 2 + 1] > v)) {
			edges[j * 2] = edges[(j - 1) * 2]
			edges[j * 2 + 1] = edges[(j - 1) * 2 + 1]
			j--
		}
		edges[j * 2] = u
		edges[j * 2 + 1] = v
	}
	return edge_count
}

@[export: 'prufer_code']
pub fn prufer_code(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 129 { return -1 }
	mode := unsafe { input[0] }
	raw_n := unsafe { input[1] }
	if raw_n < 1 || raw_n > max_vertices || (mode != 0 && mode != 1) { return -1 }
	n := int(raw_n)
	if mode == 0 {
		if length != usize(2 * n) { return -1 }
		mut code := []i64{len: max_vertices, init: 0}
		code_length := make_code(input, n, mut code)
		if code_length < 0 { return -1 }
		needed := code_length * 8
		if needed == 0 { return 0 }
		if unsafe { output == nil } || capacity < usize(needed) { return -2 }
		for i in 0 .. code_length { write_i64_le(mut output, i * 8, code[i]) }
		return i64(needed)
	}
	if n < 2 || length != usize(n) { return -1 }
	mut edges := []i64{len: (max_vertices - 1) * 2, init: 0}
	edge_count := make_decoded_edges(input, n, mut edges)
	if edge_count < 0 { return -1 }
	needed := 8 + edge_count * 16
	if needed > max_output_bytes { return -1 }
	if unsafe { output == nil } || capacity < usize(needed) { return -2 }
	write_i64_le(mut output, 0, i64(edge_count))
	for i in 0 .. edge_count {
		write_i64_le(mut output, 8 + i * 16, edges[i * 2])
		write_i64_le(mut output, 16 + i * 16, edges[i * 2 + 1])
	}
	return i64(needed)
}
