module louvain_multilevel_community_detection

const max_vertices = 8
const max_edges = 28
const max_input_length = 86
const max_parseable_length = 87
const adjacency_cells = 64

fn louvain_partition_score(adjacency [adjacency_cells]i64, community [max_vertices]int, n int) i64 {
	mut degree := [max_vertices]i64{}
	mut total_degree := i64(0)
	mut internal_directed := i64(0)
	for i in 0 .. n {
		for j in 0 .. n {
			weight := adjacency[i * max_vertices + j]
			degree[i] += weight
			if community[i] == community[j] { internal_directed += weight }
		}
		total_degree += degree[i]
	}
	mut degree_squares := i64(0)
	for i in 0 .. n {
		mut first_in_community := true
		for j in 0 .. i {
			if community[j] == community[i] {
				first_in_community = false
				break
			}
		}
		if first_in_community {
			mut community_degree := i64(0)
			for j in i .. n {
				if community[j] == community[i] { community_degree += degree[j] }
			}
			degree_squares += community_degree * community_degree
		}
	}
	return total_degree * internal_directed - degree_squares
}

@[export: 'louvain_multilevel_community_detection']
pub fn louvain_multilevel_community_detection(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_parseable_length { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 2 || n_value > max_vertices || m_value < 1 || m_value > max_edges { return -1 }
		n := int(n_value)
		m := int(m_value)
		if length != usize(2 + 3 * m) || length > max_input_length { return -1 }

		mut adjacency := [adjacency_cells]i64{}
		mut vertex_masks := [max_vertices]u64{}
		mut canonical_keys := [max_vertices]int{}
		for vertex in 0 .. n {
			vertex_masks[vertex] = u64(1) << vertex
			canonical_keys[vertex] = vertex
		}
		mut previous_u := i64(-1)
		mut previous_v := i64(-1)
		for edge in 0 .. m {
			u_value, v_value, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
			if u_value < 0 || u_value >= v_value || v_value >= n_value || weight < 1 || weight > 7 { return -1 }
			if edge > 0 && (u_value < previous_u || (u_value == previous_u && v_value <= previous_v)) { return -1 }
			u, v := int(u_value), int(v_value)
			adjacency[u * max_vertices + v] = weight
			adjacency[v * max_vertices + u] = weight
			previous_u, previous_v = u_value, v_value
		}

		for {
			mut community := [max_vertices]int{}
			for vertex in 0 .. n { community[vertex] = vertex }
			mut any_move := false
			for {
				mut sweep_moved := false
				for vertex in 0 .. n {
					current_score := louvain_partition_score(adjacency, community, n)
					old_community := community[vertex]
					mut best_community := -1
					mut best_gain := i64(0)
					mut best_key := max_vertices
					for neighbor in 0 .. n {
						if neighbor != vertex && adjacency[vertex * max_vertices + neighbor] > 0 {
							target := community[neighbor]
							if target != old_community {
								mut seen_before := false
								for earlier in 0 .. neighbor {
									if earlier != vertex && adjacency[vertex * max_vertices + earlier] > 0 && community[earlier] == target {
										seen_before = true
										break
									}
								}
								if !seen_before {
									mut target_key := max_vertices
									for member in 0 .. n {
										if community[member] == target && canonical_keys[member] < target_key { target_key = canonical_keys[member] }
									}
									community[vertex] = target
									candidate_score := louvain_partition_score(adjacency, community, n)
									community[vertex] = old_community
									gain := candidate_score - current_score
									if gain > 0 && (gain > best_gain || (gain == best_gain && target_key < best_key)) {
										best_community = target
										best_gain = gain
										best_key = target_key
									}
								}
							}
						}
					}
					if best_community >= 0 {
						community[vertex] = best_community
						sweep_moved = true
						any_move = true
					}
				}
				if !sweep_moved { break }
			}
			if !any_move { break }

			mut group_label := [max_vertices]int{}
			mut group_key := [max_vertices]int{}
			mut group_mask := [max_vertices]u64{}
			mut group_of := [max_vertices]int{}
			mut group_count := 0
			for vertex in 0 .. n {
				mut group := 0
				for group < group_count && group_label[group] != community[vertex] { group++ }
				if group == group_count {
					group_label[group] = community[vertex]
					group_key[group] = canonical_keys[vertex]
					group_count++
				}
				group_of[vertex] = group
				group_mask[group] |= vertex_masks[vertex]
			}
			if group_count >= n { return -1 }
			mut next_adjacency := [adjacency_cells]i64{}
			for i in 0 .. n {
				for j in 0 .. n {
					destination := group_of[i] * max_vertices + group_of[j]
					next_adjacency[destination] += adjacency[i * max_vertices + j]
				}
			}
			adjacency = next_adjacency
			for group in 0 .. group_count {
				vertex_masks[group] = group_mask[group]
				canonical_keys[group] = group_key[group]
			}
			n = group_count
		}

		mut labels := [max_vertices]i64{}
		for vertex in 0 .. n {
			for original in 0 .. max_vertices {
				if vertex_masks[vertex] & (u64(1) << original) != 0 { labels[original] = i64(canonical_keys[vertex]) }
			}
		}
		mut packed := u64(n) << 24
		for original in 0 .. max_vertices { packed |= u64(labels[original]) << (3 * original) }
		return i64(packed)
	}
}
