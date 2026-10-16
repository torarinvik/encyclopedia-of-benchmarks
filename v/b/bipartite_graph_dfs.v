module bipartite_graph_dfs

const max_vertices = 64
const max_edges = 256
const max_input_length = 2 + 2 * max_edges
const max_cells = max_vertices * max_vertices

@[export: 'bipartite_graph_dfs']
pub fn bipartite_graph_dfs(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + 2 * m) { return -1 }

	mut adjacency := [max_cells]bool{}
	unsafe {
		for edge in 0 .. m {
			from_value := input[2 + 2 * edge]
			to_value := input[3 + 2 * edge]
			if from_value < 0 || from_value >= i64(n) || to_value < 0 || to_value >= i64(n) { return -1 }
			from := int(from_value)
			to := int(to_value)
			adjacency[from * n + to] = true
			adjacency[to * n + from] = true
		}
	}
	mut color := [max_vertices]int{}
	mut stack := [max_vertices]int{}
	for i in 0 .. n { color[i] = -1 }
	for start in 0 .. n {
		if color[start] != -1 { continue }
		mut top := 1
		stack[0] = start
		color[start] = 0
		for top > 0 {
			top--
			node := stack[top]
			for neighbor in 0 .. n {
				if !adjacency[node * n + neighbor] { continue }
				if color[neighbor] == -1 {
					color[neighbor] = 1 - color[node]
					stack[top] = neighbor
					top++
				} else if color[neighbor] == color[node] { return 0 }
			}
		}
	}
	return 1
}
