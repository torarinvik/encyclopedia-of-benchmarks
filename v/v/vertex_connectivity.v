@[export: 'vertex_connectivity']
pub fn vertex_connectivity(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 92 { return -1 }
		if input[0] < 0 || input[0] > 10 || input[1] < 0 || input[1] > 45 { return -1 }
		n, m := int(input[0]), int(input[1])
		if length != usize(2 + 2*m) { return -1 }
		mut adjacency := [10]u64{}
		for e in 0 .. m {
			left, right := input[2+2*e], input[3+2*e]
			if left < 0 || right < 0 || left >= i64(n) || right >= i64(n) { return -1 }
			if left != right {
				u, v := int(left), int(right)
				adjacency[u] |= u64(1) << v
				adjacency[v] |= u64(1) << u
			}
		}
		if n <= 1 { return 0 }
		mut reached := u64(1)
		mut graph_queue := [10]int{}
		mut graph_head, graph_tail := 0, 1
		graph_queue[0] = 0
		for graph_head < graph_tail {
			u := graph_queue[graph_head]
			graph_head++
			for v in 0 .. n {
				bit := u64(1) << v
				if adjacency[u] & bit != 0 && reached & bit == 0 {
					reached |= bit
					graph_queue[graph_tail] = v
					graph_tail++
				}
			}
		}
		if reached != (u64(1) << n) - 1 { return 0 }
		mut best := n - 1
		for source in 0 .. n {
			for target in source+1 .. n {
				if adjacency[source] & (u64(1) << target) != 0 { continue }
				mut residual := [400]int{}
				nodes := 2*n
				for v in 0 .. n {
					capacity := 1
					if v == source || v == target { capacity = n }
					residual[(2*v)*20+2*v+1] = capacity
				}
				for u in 0 .. n {
					for v in u+1 .. n {
						if adjacency[u] & (u64(1) << v) != 0 {
							residual[(2*u+1)*20+2*v] = 1
							residual[(2*v+1)*20+2*u] = 1
						}
					}
				}
				start, sink := 2*source+1, 2*target
				mut flow := 0
				for flow < best {
					mut parent := [20]int{}
					for v in 0 .. nodes { parent[v] = -1 }
					mut queue := [20]int{}
					mut head, tail := 0, 1
					parent[start] = start
					queue[0] = start
					for head < tail && parent[sink] < 0 {
						u := queue[head]
						head++
						for v in 0 .. nodes {
							if parent[v] < 0 && residual[u*20+v] > 0 {
								parent[v] = u
								queue[tail] = v
								tail++
								if v == sink { break }
							}
						}
					}
					if parent[sink] < 0 { break }
					mut amount := best - flow
					mut v := sink
					for v != start {
						u := parent[v]
						if residual[u*20+v] < amount { amount = residual[u*20+v] }
						v = u
					}
					v = sink
					for v != start {
						u := parent[v]
						residual[u*20+v] -= amount
						residual[v*20+u] += amount
						v = u
					}
					flow += amount
				}
				if flow < best { best = flow }
				if best == 0 { return 0 }
			}
		}
		return i64(best)
	}
}
