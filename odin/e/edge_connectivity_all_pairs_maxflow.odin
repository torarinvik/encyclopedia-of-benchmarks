package edge_connectivity_all_pairs_maxflow

import "core:c"

MAX_VERTICES :: 10
MAX_EDGES :: 45
MAX_PARSEABLE :: 93

@(export)
edge_connectivity_all_pairs_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE do return -1
	if input[0] < 2 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2 + 2*m) do return -1

	var adjacency: [MAX_VERTICES * MAX_VERTICES]int
	for e := 0; e < m; e += 1 {
		left, right := input[2+2*e], input[3+2*e]
		if left < 0 || right < 0 || left >= i64(n) || right >= i64(n) || left == right do return -1
		u, v := int(left), int(right)
		if adjacency[u*MAX_VERTICES+v] != 0 do return -1
		adjacency[u*MAX_VERTICES+v] = 1
		adjacency[v*MAX_VERTICES+u] = 1
	}

	best := n - 1
	for source := 0; source < n; source += 1 {
		for sink := source + 1; sink < n; sink += 1 {
			var residual: [MAX_VERTICES * MAX_VERTICES]int
			for i := 0; i < MAX_VERTICES * MAX_VERTICES; i += 1 { residual[i] = adjacency[i] }
			flow := 0
			for flow < best {
				var parent: [MAX_VERTICES]int
				var queue: [MAX_VERTICES]int
				for v := 0; v < n; v += 1 { parent[v] = -1 }
				parent[source] = source
				head, tail := 0, 0
				queue[tail] = source; tail += 1
				for head < tail && parent[sink] < 0 {
					u := queue[head]; head += 1
					for v := 0; v < n; v += 1 {
						if parent[v] < 0 && residual[u*MAX_VERTICES+v] > 0 {
							parent[v] = u; queue[tail] = v; tail += 1
							if v == sink do break
						}
					}
				}
				if parent[sink] < 0 do break
				amount := best - flow
				v := sink
				for v != source {
					u := parent[v]
					if residual[u*MAX_VERTICES+v] < amount { amount = residual[u*MAX_VERTICES+v] }
					v = u
				}
				v = sink
				for v != source {
					u := parent[v]
					residual[u*MAX_VERTICES+v] -= amount
					residual[v*MAX_VERTICES+u] += amount
					v = u
				}
				flow += amount
			}
			if flow < best { best = flow }
			if best == 0 do return 0
		}
	}
	return i64(best)
}
