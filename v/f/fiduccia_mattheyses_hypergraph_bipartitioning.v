module fiduccia_mattheyses_hypergraph_bipartitioning

const max_n = 8
const max_m = 12
const max_input = 111
const max_parseable = 112
const bucket_count = 25

fn fm_cut(mask i64, edge_count int, degrees [max_m]int, vertices [max_m * max_n]int) int {
	mut cut := 0
	for edge in 0 .. edge_count {
		mut in_a := false
		mut in_b := false
		for slot in 0 .. degrees[edge] {
			vertex := vertices[edge * max_n + slot]
			if ((mask >> vertex) & 1) != 0 { in_a = true } else { in_b = true }
		}
		if in_a && in_b { cut++ }
	}
	return cut
}

fn fm_gain(mask i64, vertex int, edge_count int, degrees [max_m]int, vertices [max_m * max_n]int) int {
	mut gain := 0
	vertex_bit := i64(1) << vertex
	in_a_now := (mask & vertex_bit) != 0
	for edge in 0 .. edge_count {
		mut contains_vertex := false
		mut other_a := false
		mut other_b := false
		for slot in 0 .. degrees[edge] {
			member := vertices[edge * max_n + slot]
			if member == vertex { contains_vertex = true } else if ((mask >> member) & 1) != 0 { other_a = true } else { other_b = true }
		}
		if contains_vertex {
			before_cut := (other_a || in_a_now) && (other_b || !in_a_now)
			after_cut := if in_a_now { other_a } else { other_b }
			if before_cut { gain++ }
			if after_cut { gain-- }
		}
	}
	return gain
}

@[export: 'fiduccia_mattheyses_hypergraph_bipartitioning']
pub fn fiduccia_mattheyses_hypergraph_bipartitioning(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > usize(max_parseable) { return -1 }
		n_value, m_value := input[0], input[1]
		mut mask := input[2]
		if n_value < 4 || n_value > max_n || n_value % 2 != 0 || m_value < 0 || m_value > max_m { return -1 }
		n, edge_count := int(n_value), int(m_value)
		if mask < 0 || mask >= (i64(1) << n) { return -1 }
		mut initial_a := 0
		for vertex in 0 .. n { if ((mask >> vertex) & 1) != 0 { initial_a++ } }
		if initial_a != n / 2 { return -1 }

		mut degrees := [max_m]int{}
		mut vertices := [max_m * max_n]int{}
		mut position := 3
		for edge in 0 .. edge_count {
			if position >= int(length) { return -1 }
			degree_value := input[position]
			if degree_value < 2 || degree_value > i64(n) { return -1 }
			degree := int(degree_value)
			if position + 1 + degree > int(length) { return -1 }
			mut previous_vertex := i64(-1)
			for slot in 0 .. degree {
				vertex_value := input[position + 1 + slot]
				if vertex_value < 0 || vertex_value >= i64(n) || vertex_value <= previous_vertex { return -1 }
				vertices[edge * max_n + slot] = int(vertex_value)
				previous_vertex = vertex_value
			}
			degrees[edge] = degree
			position += 1 + degree
		}
		if position != int(length) || length > usize(max_input) { return -1 }

		mut current_cut := fm_cut(mask, edge_count, degrees, vertices)
		mut a_size := initial_a
		mut pass_count := 0
		for pass_count <= edge_count {
			pass_start_mask := mask
			pass_start_cut := current_cut
			mut best_prefix_mask := mask
			mut best_prefix_cut := current_cut
			mut working_a_size := a_size
			mut locked := [max_n]bool{}
			mut moves := 0
			for moves < n {
				mut bucket_best := [bucket_count]int{}
				mut bucket_balance := [bucket_count]int{}
				for bucket in 0 .. bucket_count { bucket_best[bucket] = -1 }
				for vertex in 0 .. n {
					if !locked[vertex] {
						bit := i64(1) << vertex
						in_a := (mask & bit) != 0
						resulting_a := working_a_size + 1
						if in_a { resulting_a = working_a_size - 1 }
						if resulting_a >= n / 2 - 1 && resulting_a <= n / 2 + 1 {
							gain := fm_gain(mask, vertex, edge_count, degrees, vertices)
							bucket_index := gain + max_m
							balance := 2 * resulting_a - n
							if balance < 0 { balance = -balance }
							if bucket_best[bucket_index] < 0 || balance < bucket_balance[bucket_index] ||
								(balance == bucket_balance[bucket_index] && vertex < bucket_best[bucket_index]) {
								bucket_best[bucket_index] = vertex
								bucket_balance[bucket_index] = balance
							}
						}
					}
				}
				mut selected := n
				mut selected_gain := 0
				mut bucket := bucket_count
				for bucket > 0 {
					bucket--
					if bucket_best[bucket] >= 0 {
						selected = bucket_best[bucket]
						selected_gain = bucket - max_m
						break
					}
				}
				if selected == n { break }
				bit := i64(1) << selected
				if (mask & bit) != 0 {
					mask -= bit
					working_a_size--
				} else {
					mask += bit
					working_a_size++
				}
				locked[selected] = true
				current_cut -= selected_gain
				moves++
				if current_cut < best_prefix_cut {
					best_prefix_cut = current_cut
					best_prefix_mask = mask
				}
			}
			if best_prefix_cut < pass_start_cut {
				mask = best_prefix_mask
				current_cut = best_prefix_cut
				a_size = 0
				for vertex in 0 .. n { if ((mask >> vertex) & 1) != 0 { a_size++ } }
				pass_count++
			} else {
				mask = pass_start_mask
				current_cut = pass_start_cut
				break
			}
		}
		return i64(current_cut * 256) + mask
	}
}
