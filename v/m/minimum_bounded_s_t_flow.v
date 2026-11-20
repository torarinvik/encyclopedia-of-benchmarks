module minimum_bounded_s_t_flow

const max_n = 6
const max_m = 8
const max_input_length = 37
const node_cap = 8

fn feasible(input &i64, n int, m int, source int, sink int, flow_cap i64) bool {
	unsafe {
		mut residual := [64]i64{}
		mut balance := [max_n]i64{}
		for index in 0 .. m {
			offset := 4 + 4 * index
			u := int(input[offset])
			v := int(input[offset + 1])
			lower := input[offset + 2]
			upper := input[offset + 3]
			residual[u * node_cap + v] += upper - lower
			balance[u] -= lower
			balance[v] += lower
		}
		residual[sink * node_cap + source] += flow_cap

		super_source := n
		super_sink := n + 1
		node_count := n + 2
		mut demand := i64(0)
		for vertex in 0 .. n {
			if balance[vertex] > 0 {
				residual[super_source * node_cap + vertex] += balance[vertex]
				demand += balance[vertex]
			} else if balance[vertex] < 0 {
				residual[vertex * node_cap + super_sink] -= balance[vertex]
			}
		}

		mut flow := i64(0)
		for flow < demand {
			mut parent := [node_cap]int{}
			for vertex in 0 .. node_count { parent[vertex] = -1 }
			mut queue := [node_cap]int{}
			mut head, tail := 0, 0
			parent[super_source] = super_source
			queue[tail] = super_source
			tail++
			for head < tail && parent[super_sink] < 0 {
				u := queue[head]
				head++
				for v in 0 .. node_count {
					if residual[u * node_cap + v] > 0 && parent[v] < 0 {
						parent[v] = u
						queue[tail] = v
						tail++
						if v == super_sink { break }
					}
				}
			}
			if parent[super_sink] < 0 { break }
			mut amount := demand - flow
			mut vertex := super_sink
			for vertex != super_source {
				u := parent[vertex]
				if residual[u * node_cap + vertex] < amount {
					amount = residual[u * node_cap + vertex]
				}
				vertex = u
			}
			vertex = super_sink
			for vertex != super_source {
				u := parent[vertex]
				residual[u * node_cap + vertex] -= amount
				residual[vertex * node_cap + u] += amount
				vertex = u
			}
			flow += amount
		}
		return flow == demand
	}
}

@[export: 'minimum_bounded_s_t_flow']
pub fn minimum_bounded_s_t_flow(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input_length {
			return -1
		}
		n_arg, m_arg := input[0], input[1]
		source_arg, sink_arg := input[2], input[3]
		if n_arg < 2 || n_arg > i64(max_n) || m_arg < 0 || m_arg > i64(max_m) {
			return -1
		}
		if source_arg < 0 || source_arg >= n_arg || sink_arg < 0 || sink_arg >= n_arg ||
			source_arg == sink_arg {
			return -1
		}
		n, m := int(n_arg), int(m_arg)
		source, sink := int(source_arg), int(sink_arg)
		if length != usize(4 + 4 * m) {
			return -1
		}

		mut upper_bound := i64(0)
		for index in 0 .. m {
			offset := 4 + 4 * index
			u_arg, v_arg := input[offset], input[offset + 1]
			lower, upper := input[offset + 2], input[offset + 3]
			if u_arg < 0 || u_arg >= n_arg || v_arg < 0 || v_arg >= n_arg ||
				lower < 0 || upper < lower || upper > 2 {
				return -1
			}
			if int(u_arg) == source && int(v_arg) != source {
				upper_bound += upper
			}
		}

		mut low := i64(0)
		mut high := upper_bound + 1
		for low < high {
			middle := low + (high - low) / 2
			if feasible(input, n, m, source, sink, middle) {
				high = middle
			} else {
				low = middle + 1
			}
		}
		if low > upper_bound {
			return -2
		}
		return low
	}
}
