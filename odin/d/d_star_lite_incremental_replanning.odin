package d_star_lite_incremental_replanning

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 48
MAX_EVENTS :: 16
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(199)
INF :: i64(1_000_000_000)

Key :: struct { first, second: i64 }

manhattan :: proc "contextless" (left, right, width: int) -> i64 {
	left_row, right_row := left / width, right / width
	left_column, right_column := left % width, right % width
	row_distance := left_row - right_row
	if row_distance < 0 do row_distance = -row_distance
	column_distance := left_column - right_column
	if column_distance < 0 do column_distance = -column_distance
	return i64(row_distance + column_distance)
}

calculate_key :: proc "contextless" (vertex, start, width: int, km: i64,
		g, rhs: ^[MAX_VERTICES]i64) -> Key {
	minimum := min(g[vertex], rhs[vertex])
	return Key{minimum + manhattan(start, vertex, width) + km, minimum}
}

key_less :: proc "contextless" (left, right: Key) -> bool {
	return left.first < right.first || (left.first == right.first && left.second < right.second)
}

update_vertex :: proc "contextless" (vertex, goal, start, width, edge_count: int, km: i64,
		tails, heads: ^[MAX_EDGES]int, costs: ^[MAX_EDGES]i64,
		g: ^[MAX_VERTICES]i64, rhs: ^[MAX_VERTICES]i64,
		in_open: ^[MAX_VERTICES]bool, key_first, key_second: ^[MAX_VERTICES]i64) {
	if vertex != goal {
		best := INF
		for edge := 0; edge < edge_count; edge += 1 {
			if tails[edge] == vertex {
				candidate := costs[edge] + g[heads[edge]]
				if candidate < best do best = candidate
			}
		}
		rhs[vertex] = best
	}

	in_open[vertex] = false
	if g[vertex] != rhs[vertex] {
		key := calculate_key(vertex, start, width, km, g, rhs)
		in_open[vertex] = true
		key_first[vertex], key_second[vertex] = key.first, key.second
	}
}

compute_shortest_path :: proc "contextless" (start, goal, width, vertex_count, edge_count: int, km: i64,
		tails, heads: ^[MAX_EDGES]int, costs: ^[MAX_EDGES]i64,
		g, rhs: ^[MAX_VERTICES]i64, in_open: ^[MAX_VERTICES]bool,
		key_first, key_second: ^[MAX_VERTICES]i64) {
	for {
		top := MAX_VERTICES
		top_key := Key{0, 0}
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			if in_open[vertex] {
				key := Key{key_first[vertex], key_second[vertex]}
				if top == MAX_VERTICES || key_less(key, top_key) ||
					(key.first == top_key.first && key.second == top_key.second && vertex < top) {
					top, top_key = vertex, key
				}
			}
		}

		start_key := calculate_key(start, start, width, km, g, rhs)
		if top == MAX_VERTICES || (!key_less(top_key, start_key) && rhs[start] == g[start]) do break

		old_key := top_key
		new_key := calculate_key(top, start, width, km, g, rhs)
		if key_less(old_key, new_key) {
			key_first[top], key_second[top] = new_key.first, new_key.second
			continue
		}

		in_open[top] = false
		if g[top] > rhs[top] {
			g[top] = rhs[top]
			for edge := 0; edge < edge_count; edge += 1 {
				if heads[edge] == top {
					update_vertex(tails[edge], goal, start, width, edge_count, km,
						tails, heads, costs, g, rhs, in_open, key_first, key_second)
				}
			}
		} else {
			g[top] = INF
			update_vertex(top, goal, start, width, edge_count, km,
				tails, heads, costs, g, rhs, in_open, key_first, key_second)
			for edge := 0; edge < edge_count; edge += 1 {
				if heads[edge] == top {
					update_vertex(tails[edge], goal, start, width, edge_count, km,
						tails, heads, costs, g, rhs, in_open, key_first, key_second)
				}
			}
		}
	}
}

@(export)
d_star_lite_incremental_replanning :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	height_value, width_value := input[0], input[1]
	edge_count_value, event_count_value := input[2], input[3]
	if height_value < 1 || height_value > 4 || width_value < 1 || width_value > 4 ||
		edge_count_value < 0 || event_count_value < 0 || event_count_value > MAX_EVENTS do return -1
	height, width := int(height_value), int(width_value)
	vertex_count := height * width
	if vertex_count < 2 || vertex_count > MAX_VERTICES do return -1
	maximum_edges := 2 * (height * (width - 1) + width * (height - 1))
	if edge_count_value > i64(maximum_edges) || edge_count_value > MAX_EDGES do return -1
	edge_count, event_count := int(edge_count_value), int(event_count_value)
	start_value, goal_value := input[4], input[5]
	if start_value < 0 || start_value >= i64(vertex_count) || goal_value < 0 || goal_value >= i64(vertex_count) do return -1
	if length != c.size_t(6 + 3 * edge_count + 3 * event_count) do return -1

	var tails: [MAX_EDGES]int
	var heads: [MAX_EDGES]int
	var costs: [MAX_EDGES]i64
	for edge := 0; edge < edge_count; edge += 1 {
		offset := 6 + 3 * edge
		tail_value, head_value, cost := input[offset], input[offset+1], input[offset+2]
		if tail_value < 0 || tail_value >= i64(vertex_count) || head_value < 0 ||
			head_value >= i64(vertex_count) || cost < 1 || cost > 9 do return -1
		tail, head := int(tail_value), int(head_value)
		if manhattan(tail, head, width) != 1 do return -1
		for previous := 0; previous < edge; previous += 1 {
			if tails[previous] == tail && heads[previous] == head do return -1
		}
		tails[edge], heads[edge], costs[edge] = tail, head, cost
	}

	var event_starts: [MAX_EVENTS]int
	var event_edges: [MAX_EVENTS]int
	var event_costs: [MAX_EVENTS]i64
	for event := 0; event < event_count; event += 1 {
		offset := 6 + 3 * edge_count + 3 * event
		new_start, edge_id, new_cost := input[offset], input[offset+1], input[offset+2]
		if new_start < 0 || new_start >= i64(vertex_count) || edge_id < 0 ||
			edge_id >= i64(edge_count) || new_cost < 1 || new_cost > 9 do return -1
		event_starts[event], event_edges[event], event_costs[event] = int(new_start), int(edge_id), new_cost
	}

	var g: [MAX_VERTICES]i64
	var rhs: [MAX_VERTICES]i64
	var in_open: [MAX_VERTICES]bool
	var key_first: [MAX_VERTICES]i64
	var key_second: [MAX_VERTICES]i64
	for vertex := 0; vertex < vertex_count; vertex += 1 { g[vertex], rhs[vertex] = INF, INF }
	initial_start, goal := int(start_value), int(goal_value)
	current_start, last_start := initial_start, initial_start
	km: i64 = 0
	rhs[goal] = 0
	update_vertex(goal, goal, current_start, width, edge_count, km,
		&tails, &heads, &costs, &g, &rhs, &in_open, &key_first, &key_second)

	checksum: i64 = 0
	for event := 0; event < event_count; event += 1 {
		new_start := event_starts[event]
		km += manhattan(last_start, new_start, width)
		last_start, current_start = new_start, new_start
		costs[event_edges[event]] = event_costs[event]
		update_vertex(tails[event_edges[event]], goal, current_start, width, edge_count, km,
			&tails, &heads, &costs, &g, &rhs, &in_open, &key_first, &key_second)
		compute_shortest_path(current_start, goal, width, vertex_count, edge_count, km,
			&tails, &heads, &costs, &g, &rhs, &in_open, &key_first, &key_second)

		distance_code: i64 = 136
		next_code: i64 = 0
		if g[current_start] < INF {
			distance_code = g[current_start]
			if current_start != goal {
				next_vertex := MAX_VERTICES
				for edge := 0; edge < edge_count; edge += 1 {
					if tails[edge] == current_start && costs[edge] + g[heads[edge]] == g[current_start] && heads[edge] < next_vertex {
						next_vertex = heads[edge]
					}
				}
				if next_vertex < MAX_VERTICES do next_code = i64(next_vertex + 1)
			}
		}
		checksum += i64(event + 1) * (distance_code + 1) * (next_code + 1)
	}
	return checksum
}
