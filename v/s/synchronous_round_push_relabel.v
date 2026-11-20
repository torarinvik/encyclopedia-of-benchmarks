module synchronous_round_push_relabel

const max_vertices = 8
const max_arcs = 24
const max_input_length = usize(77)
const max_capacity = i64(15)

@[export: 'synchronous_round_push_relabel']
pub fn synchronous_round_push_relabel(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input_length { return -1 }
		raw_n := input[0]
		raw_m := input[1]
		raw_source := input[2]
		raw_sink := input[3]
		if raw_n < 2 || raw_n > max_vertices || raw_m < 0 || raw_m > max_arcs ||
			raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n ||
			raw_source == raw_sink || length != usize(4 + 3 * raw_m) { return -1 }
		n := int(raw_n)
		m := int(raw_m)
		source := int(raw_source)
		sink := int(raw_sink)
		if length != usize(4 + 3 * m) { return -1 }
		mut capacity := [64]i64{}
		for index in 0 .. m {
			offset := 4 + 3 * index
			u := input[offset]
			v := input[offset + 1]
			amount := input[offset + 2]
			if u < 0 || u >= raw_n || v < 0 || v >= raw_n || u == v || amount < 0 || amount > max_capacity {
				return -1
			}
			capacity[int(u) * max_vertices + int(v)] += amount
		}

		mut residual := capacity
		mut excess := [8]i64{}
		mut height := [8]int{}
		height[source] = n
		for vertex in 0 .. n {
			if vertex == source { continue }
			forward := source * max_vertices + vertex
			reverse := vertex * max_vertices + source
			amount := residual[forward]
			if amount != 0 {
				residual[forward] = 0
				residual[reverse] += amount
				excess[source] -= amount
				excess[vertex] += amount
			}
		}

		for {
			mut active := [8]int{}
			mut active_count := 0
			for vertex in 0 .. n {
				if vertex != source && vertex != sink && excess[vertex] > 0 && height[vertex] < n {
					active[active_count] = vertex
					active_count++
				}
			}
			if active_count == 0 { return excess[sink] }

			mut change := [8]i64{}
			for ai in 0 .. active_count {
				u := active[ai]
				mut remaining := excess[u]
				for neighbor in 0 .. n {
					if remaining <= 0 { break }
					forward := u * max_vertices + neighbor
					reverse := neighbor * max_vertices + u
					if residual[forward] > 0 && height[u] == height[neighbor] + 1 {
						amount := if remaining < residual[forward] { remaining } else { residual[forward] }
						residual[forward] -= amount
						residual[reverse] += amount
						change[u] -= amount
						change[neighbor] += amount
						remaining -= amount
					}
				}
			}

			mut next_excess := excess
			mut next_height := height
			for vertex in 0 .. n { next_excess[vertex] += change[vertex] }
			for ai in 0 .. active_count {
				u := active[ai]
				if next_excess[u] <= 0 { continue }
				mut minimum := 2 * max_vertices + 1
				for neighbor in 0 .. n {
					if residual[u * max_vertices + neighbor] > 0 && height[neighbor] < minimum {
						minimum = height[neighbor]
					}
				}
				next_height[u] = if minimum == 2 * max_vertices + 1 { n + 1 } else { minimum + 1 }
			}
			excess = next_excess
			height = next_height
		}
	}
}
