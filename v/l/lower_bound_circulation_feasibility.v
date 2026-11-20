module lower_bound_circulation_feasibility

const max_n = 6
const max_m = 8
const max_input_length = 35
const node_cap = 8

@[export: 'lower_bound_circulation_feasibility']
pub fn lower_bound_circulation_feasibility(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length {
			return -1
		}
		n_arg, m_arg := input[0], input[1]
		if n_arg < 1 || n_arg > i64(max_n) || m_arg < 0 || m_arg > i64(max_m) {
			return -1
		}
		n, m := int(n_arg), int(m_arg)
		if length != usize(2 + 4 * m) {
			return -1
		}

		mut residual := [64]i64{}
		mut balance := [max_n]i64{}
		for index in 0 .. m {
			offset := 2 + 4 * index
			u_arg, v_arg := input[offset], input[offset + 1]
			lower, upper := input[offset + 2], input[offset + 3]
			if u_arg < 0 || u_arg >= n_arg || v_arg < 0 || v_arg >= n_arg ||
				lower < 0 || upper < lower || upper > 2 {
				return -1
			}
			u, v := int(u_arg), int(v_arg)
			residual[u * node_cap + v] += upper - lower
			balance[u] -= lower
			balance[v] += lower
		}

		source, sink := n, n + 1
		node_count := n + 2
		mut demand := i64(0)
		for vertex in 0 .. n {
			if balance[vertex] > 0 {
				residual[source * node_cap + vertex] += balance[vertex]
				demand += balance[vertex]
			} else if balance[vertex] < 0 {
				residual[vertex * node_cap + sink] -= balance[vertex]
			}
		}

		mut flow := i64(0)
		for flow < demand {
			mut parent := [node_cap]int{}
			for vertex in 0 .. node_count {
				parent[vertex] = -1
			}
			mut queue := [node_cap]int{}
			mut head, tail := 0, 0
			parent[source] = source
			queue[tail] = source
			tail++
			for head < tail && parent[sink] < 0 {
				u := queue[head]
				head++
				for v in 0 .. node_count {
					if residual[u * node_cap + v] > 0 && parent[v] < 0 {
						parent[v] = u
						queue[tail] = v
						tail++
						if v == sink {
							break
						}
					}
				}
			}
			if parent[sink] < 0 {
				break
			}
			mut amount := demand - flow
			mut vertex := sink
			for vertex != source {
				u := parent[vertex]
				if residual[u * node_cap + vertex] < amount {
					amount = residual[u * node_cap + vertex]
				}
				vertex = u
			}
			vertex = sink
			for vertex != source {
				u := parent[vertex]
				residual[u * node_cap + vertex] -= amount
				residual[vertex * node_cap + u] += amount
				vertex = u
			}
			flow += amount
		}
		if flow == demand {
			return 1
		}
		return 0
	}
}
