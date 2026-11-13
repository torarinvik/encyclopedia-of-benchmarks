module edge_connectivity_all_pairs_maxflow

const max_vertices = 10
const max_edges = 45
const max_parseable = 93

fn pair_flow(adjacency [max_vertices * max_vertices]int, n int, source int, sink int, limit int) int {
	mut residual := adjacency
	mut flow := 0
	for flow < limit {
		mut parent := [max_vertices]int{}
		mut queue := [max_vertices]int{}
		for v in 0 .. n { parent[v] = -1 }
		parent[source] = source
		mut head, tail := 0, 1
		queue[0] = source
		for head < tail && parent[sink] < 0 {
			u := queue[head]
			head++
			for v in 0 .. n {
				if parent[v] < 0 && residual[u * max_vertices + v] > 0 {
					parent[v] = u
					queue[tail] = v
					tail++
					if v == sink { break }
				}
			}
		}
		if parent[sink] < 0 { break }
		mut amount := limit - flow
		mut v := sink
		for v != source {
			u := parent[v]
			if residual[u * max_vertices + v] < amount { amount = residual[u * max_vertices + v] }
			v = u
		}
		v = sink
		for v != source {
			u := parent[v]
			residual[u * max_vertices + v] -= amount
			residual[v * max_vertices + u] += amount
			v = u
		}
		flow += amount
	}
	return flow
}

@[export: 'edge_connectivity_all_pairs_maxflow']
pub fn edge_connectivity_all_pairs_maxflow(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_parseable) { return -1 }
		if input[0] < 2 || input[0] > i64(max_vertices) || input[1] < 0 || input[1] > i64(max_edges) { return -1 }
		n, m := int(input[0]), int(input[1])
		if length != usize(2 + 2 * m) { return -1 }

		mut adjacency := [max_vertices * max_vertices]int{}
		for e in 0 .. m {
			left, right := input[2 + 2 * e], input[3 + 2 * e]
			if left < 0 || right < 0 || left >= i64(n) || right >= i64(n) || left == right { return -1 }
			u, v := int(left), int(right)
			if adjacency[u * max_vertices + v] != 0 { return -1 }
			adjacency[u * max_vertices + v] = 1
			adjacency[v * max_vertices + u] = 1
		}

		mut best := n - 1
		for source in 0 .. n {
			for sink in source + 1 .. n {
				flow := pair_flow(adjacency, n, source, sink, best)
				if flow < best { best = flow }
				if best == 0 { return 0 }
			}
		}
		return i64(best)
	}
}
