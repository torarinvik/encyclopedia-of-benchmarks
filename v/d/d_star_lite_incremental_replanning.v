module d_star_lite_incremental_replanning

const max_n = 16
const max_e = 48
const max_q = 16
const max_input = 198
const max_parseable = 199
const inf = i64(1000000000)

fn dsl_manhattan(left int, right int, width int) i64 {
	left_row := left / width
	right_row := right / width
	left_col := left % width
	right_col := right % width
	mut row_delta := left_row - right_row
	mut col_delta := left_col - right_col
	if row_delta < 0 { row_delta = -row_delta }
	if col_delta < 0 { col_delta = -col_delta }
	return i64(row_delta + col_delta)
}

fn dsl_key1(g [max_n]i64, rhs [max_n]i64, node int, start int, width int, km i64) i64 {
	base := if g[node] < rhs[node] { g[node] } else { rhs[node] }
	if base >= inf { return inf }
	return base + dsl_manhattan(start, node, width) + km
}

fn dsl_pair_less(left_first i64, left_second i64, right_first i64, right_second i64) bool {
	return left_first < right_first || (left_first == right_first && left_second < right_second)
}

fn dsl_update_vertex(mut g [max_n]i64, mut rhs [max_n]i64, mut in_open [max_n]bool,
	mut queue_first [max_n]i64, mut queue_second [max_n]i64,
	edge_from [max_e]int, edge_to [max_e]int, edge_cost [max_e]i64,
	edge_count int, node int, goal int, start int, width int, km i64) {
	if node != goal {
		mut best := inf
		for edge in 0 .. edge_count {
			if edge_from[edge] == node && g[edge_to[edge]] < inf {
				candidate := edge_cost[edge] + g[edge_to[edge]]
				if candidate < best { best = candidate }
			}
		}
		rhs[node] = best
	}
	in_open[node] = false
	if g[node] != rhs[node] {
		in_open[node] = true
		queue_first[node] = dsl_key1(g, rhs, node, start, width, km)
		queue_second[node] = if g[node] < rhs[node] { g[node] } else { rhs[node] }
	}
}

@[export: 'd_star_lite_incremental_replanning']
pub fn d_star_lite_incremental_replanning(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > usize(max_parseable) { return -1 }
		height_value := input[0]
		width_value := input[1]
		edge_value := input[2]
		query_value := input[3]
		if height_value < 1 || height_value > 4 || width_value < 1 || width_value > 4 { return -1 }
		height, width := int(height_value), int(width_value)
		node_count := height * width
		if node_count < 2 || node_count > max_n { return -1 }
		if edge_value < 0 || edge_value > max_e || query_value < 0 || query_value > max_q { return -1 }
		edge_count, query_count := int(edge_value), int(query_value)
		max_edges := 2 * (height * (width - 1) + width * (height - 1))
		if edge_count > max_edges || int(length) != 6 + 3 * edge_count + 3 * query_count || length > usize(max_input) { return -1 }
		start_value, goal_value := input[4], input[5]
		if start_value < 0 || goal_value < 0 || start_value >= i64(node_count) || goal_value >= i64(node_count) { return -1 }

		mut edge_from := [max_e]int{}
		mut edge_to := [max_e]int{}
		mut edge_cost := [max_e]i64{}
		for edge in 0 .. edge_count {
			base := 6 + 3 * edge
			from_value, to_value, cost := input[base], input[base + 1], input[base + 2]
			if from_value < 0 || to_value < 0 || from_value >= i64(node_count) || to_value >= i64(node_count) || cost < 1 || cost > 9 { return -1 }
			from_node, to_node := int(from_value), int(to_value)
			if dsl_manhattan(from_node, to_node, width) != 1 { return -1 }
			for previous in 0 .. edge {
				if edge_from[previous] == from_node && edge_to[previous] == to_node { return -1 }
			}
			edge_from[edge], edge_to[edge], edge_cost[edge] = from_node, to_node, cost
		}

		mut event_start := [max_q]int{}
		mut event_edge := [max_q]int{}
		mut event_cost := [max_q]i64{}
		for event in 0 .. query_count {
			base := 6 + 3 * edge_count + 3 * event
			next_start, edge_index, cost := input[base], input[base + 1], input[base + 2]
			if next_start < 0 || next_start >= i64(node_count) || edge_index < 0 || edge_index >= i64(edge_count) || cost < 1 || cost > 9 { return -1 }
			event_start[event], event_edge[event], event_cost[event] = int(next_start), int(edge_index), cost
		}

		mut g := [max_n]i64{}
		mut rhs := [max_n]i64{}
		mut in_open := [max_n]bool{}
		mut queue_first := [max_n]i64{}
		mut queue_second := [max_n]i64{}
		for node in 0 .. node_count { g[node], rhs[node] = inf, inf }
		mut start := int(start_value)
		goal := int(goal_value)
		mut last_start := start
		mut km := i64(0)
		rhs[goal] = 0
		in_open[goal] = true
		queue_first[goal] = dsl_key1(g, rhs, goal, start, width, km)
		queue_second[goal] = 0

		mut checksum := i64(0)
		for event in 0 .. query_count {
			start = event_start[event]
			km += dsl_manhattan(last_start, start, width)
			last_start = start
			edge_cost[event_edge[event]] = event_cost[event]
			dsl_update_vertex(mut g, mut rhs, mut in_open, mut queue_first, mut queue_second,
				edge_from, edge_to, edge_cost, edge_count, edge_from[event_edge[event]], goal, start, width, km)

			for {
				mut selected := node_count
				for candidate_node in 0 .. node_count {
					if in_open[candidate_node] {
						if selected == node_count {
							selected = candidate_node
						} else if dsl_pair_less(queue_first[candidate_node], queue_second[candidate_node], queue_first[selected], queue_second[selected]) ||
							(queue_first[candidate_node] == queue_first[selected] && queue_second[candidate_node] == queue_second[selected] && candidate_node < selected) {
							selected = candidate_node
						}
					}
				}
				if selected == node_count { break }
				start_key_first := dsl_key1(g, rhs, start, start, width, km)
				start_key_second := if g[start] < rhs[start] { g[start] } else { rhs[start] }
				top_before_start := dsl_pair_less(queue_first[selected], queue_second[selected], start_key_first, start_key_second)
				if !top_before_start && rhs[start] == g[start] { break }

				old_first, old_second := queue_first[selected], queue_second[selected]
				in_open[selected] = false
				new_first := dsl_key1(g, rhs, selected, start, width, km)
				new_second := if g[selected] < rhs[selected] { g[selected] } else { rhs[selected] }
				if dsl_pair_less(old_first, old_second, new_first, new_second) {
					in_open[selected] = true
					queue_first[selected], queue_second[selected] = new_first, new_second
				} else if g[selected] > rhs[selected] {
					g[selected] = rhs[selected]
					for edge in 0 .. edge_count {
						if edge_to[edge] == selected {
							dsl_update_vertex(mut g, mut rhs, mut in_open, mut queue_first, mut queue_second,
								edge_from, edge_to, edge_cost, edge_count, edge_from[edge], goal, start, width, km)
						}
					}
				} else {
					g[selected] = inf
					dsl_update_vertex(mut g, mut rhs, mut in_open, mut queue_first, mut queue_second,
						edge_from, edge_to, edge_cost, edge_count, selected, goal, start, width, km)
					for edge in 0 .. edge_count {
						if edge_to[edge] == selected {
							dsl_update_vertex(mut g, mut rhs, mut in_open, mut queue_first, mut queue_second,
								edge_from, edge_to, edge_cost, edge_count, edge_from[edge], goal, start, width, km)
						}
					}
				}
			}

			mut next_code := i64(0)
			if start != goal && g[start] < inf {
				mut best := inf
				mut best_node := node_count
				for edge in 0 .. edge_count {
					if edge_from[edge] == start && g[edge_to[edge]] < inf {
						candidate := edge_cost[edge] + g[edge_to[edge]]
						if candidate < best || (candidate == best && edge_to[edge] < best_node) {
							best, best_node = candidate, edge_to[edge]
						}
					}
				}
				if best == g[start] && best_node < node_count { next_code = i64(best_node + 1) }
			}
			distance_code := if g[start] < inf { g[start] } else { i64(136) }
			checksum += i64(event + 1) * (distance_code + 1) * (next_code + 1)
		}
		return checksum
	}
}
