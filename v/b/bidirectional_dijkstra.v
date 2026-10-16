module bidirectional_dijkstra

const max_vertices = 64
const max_edges = 256
const max_weight = 1000000
const inf = i64(1000000000)

@[export: 'bidirectional_dijkstra']
pub fn bidirectional_dijkstra(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 4 { return -1 }
		nv := input[0]
		mv := input[1]
		source_value := input[2]
		target_value := input[3]
		if nv < 1 || nv > max_vertices || mv < 0 || mv > max_edges { return -1 }
		if source_value < 0 || source_value >= nv || target_value < 0 || target_value >= nv { return -1 }
		n := int(nv)
		m := int(mv)
		if length != usize(4 + 3 * m) { return -1 }
		for edge in 0 .. m {
			from := input[4 + 3 * edge]
			to := input[5 + 3 * edge]
			weight := input[6 + 3 * edge]
			if from < 0 || from >= nv || to < 0 || to >= nv || weight < 0 || weight > max_weight { return -1 }
		}
		source := int(source_value)
		target := int(target_value)
		if source == target { return 0 }

		mut forward := [max_vertices]i64{}
		mut backward := [max_vertices]i64{}
		mut settled_forward := [max_vertices]bool{}
		mut settled_backward := [max_vertices]bool{}
		for vertex in 0 .. n {
			forward[vertex] = inf
			backward[vertex] = inf
		}
		forward[source] = 0
		backward[target] = 0
		mut best := inf

		for _ in 0 .. 2 * n {
			mut next_forward := n
			mut next_backward := n
			mut min_forward := inf
			mut min_backward := inf
			for vertex in 0 .. n {
				if !settled_forward[vertex] && forward[vertex] < min_forward {
					min_forward = forward[vertex]
					next_forward = vertex
				}
				if !settled_backward[vertex] && backward[vertex] < min_backward {
					min_backward = backward[vertex]
					next_backward = vertex
				}
			}
			if next_forward == n || next_backward == n { break }
			if best != inf && min_forward + min_backward >= best { break }

			if min_forward <= min_backward {
				current := next_forward
				settled_forward[current] = true
				if backward[current] != inf && forward[current] + backward[current] < best {
					best = forward[current] + backward[current]
				}
				for edge in 0 .. m {
					if int(input[4 + 3 * edge]) != current { continue }
					to := int(input[5 + 3 * edge])
					candidate := forward[current] + input[6 + 3 * edge]
					if !settled_forward[to] && candidate < forward[to] { forward[to] = candidate }
					if backward[to] != inf && candidate + backward[to] < best { best = candidate + backward[to] }
				}
			} else {
				current := next_backward
				settled_backward[current] = true
				if forward[current] != inf && forward[current] + backward[current] < best {
					best = forward[current] + backward[current]
				}
				for edge in 0 .. m {
					if int(input[5 + 3 * edge]) != current { continue }
					from := int(input[4 + 3 * edge])
					candidate := backward[current] + input[6 + 3 * edge]
					if !settled_backward[from] && candidate < backward[from] { backward[from] = candidate }
					if forward[from] != inf && forward[from] + input[6 + 3 * edge] + backward[current] < best {
						best = forward[from] + input[6 + 3 * edge] + backward[current]
					}
				}
			}
		}
		if best == inf { return -1 }
		return best
	}
}
