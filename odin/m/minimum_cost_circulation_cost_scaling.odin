package minimum_cost_circulation_cost_scaling

import "core:c"

MAX_N :: 8
MAX_M :: 10
MAX_INPUT_LENGTH :: 43
MAX_ARCS :: 2 * MAX_M
COST_OFFSET :: 81

Residual_Arc :: struct {
	from_vertex: int,
	to_vertex: int,
	reverse_index: int,
	capacity: i64,
	cost: i64,
}

@(export)
minimum_cost_circulation_cost_scaling :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_arg, m_arg := input[0], input[1]
	if n_arg < 1 || n_arg > MAX_N || m_arg < 0 || m_arg > MAX_M do return -1
	n, m := int(n_arg), int(m_arg)
	if length != c.size_t(2 + 4 * m) do return -1

	var edges: [MAX_ARCS]Residual_Arc
	max_scaled_cost: i64 = 0
	for index := 0; index < m; index += 1 {
		offset := 2 + 4 * index
		from_arg, to_arg := input[offset], input[offset+1]
		capacity, cost := input[offset+2], input[offset+3]
		if from_arg < 0 || from_arg >= n_arg || to_arg < 0 || to_arg >= n_arg ||
			capacity < 0 || capacity > 2 || cost < -4 || cost > 4 do return -1
		from_vertex, to_vertex := int(from_arg), int(to_arg)
		scaled_cost := cost * i64(n+1)
		forward, reverse := 2*index, 2*index+1
		edges[forward] = Residual_Arc{from_vertex, to_vertex, reverse, capacity, scaled_cost}
		edges[reverse] = Residual_Arc{to_vertex, from_vertex, forward, 0, -scaled_cost}
		magnitude := scaled_cost
		if magnitude < 0 { magnitude = -magnitude }
		if magnitude > max_scaled_cost { max_scaled_cost = magnitude }
	}

	epsilon: i64 = 1
	for epsilon < max_scaled_cost { epsilon *= 2 }
	var price: [MAX_N]i64
	arc_count := 2 * m
	for epsilon > 1 {
		epsilon /= 2
		var excess: [MAX_N]i64
		var queue: [MAX_N]int
		var queued: [MAX_N]bool
		head, tail, queue_count := 0, 0, 0

		for edge_index := 0; edge_index < arc_count; edge_index += 1 {
			if edges[edge_index].capacity <= 0 { continue }
			from_vertex, to_vertex := edges[edge_index].from_vertex, edges[edge_index].to_vertex
			reduced_cost := edges[edge_index].cost + price[from_vertex] - price[to_vertex]
			if reduced_cost < 0 {
				amount := edges[edge_index].capacity
				edges[edge_index].capacity = 0
				edges[edges[edge_index].reverse_index].capacity += amount
				excess[from_vertex] -= amount
				excess[to_vertex] += amount
			}
		}

		for vertex := 0; vertex < n; vertex += 1 {
			if excess[vertex] > 0 {
				queue[tail] = vertex
				tail = (tail + 1) % n
				queue_count += 1
				queued[vertex] = true
			}
		}
		for queue_count > 0 {
			vertex := queue[head]
			head = (head + 1) % n
			queue_count -= 1
			queued[vertex] = false
			for excess[vertex] > 0 {
				admissible := -1
				for edge_index := 0; edge_index < arc_count; edge_index += 1 {
					if edges[edge_index].from_vertex != vertex || edges[edge_index].to_vertex == vertex ||
						edges[edge_index].capacity <= 0 { continue }
					to_vertex := edges[edge_index].to_vertex
					if edges[edge_index].cost + price[vertex] - price[to_vertex] < 0 {
						admissible = edge_index
						break
					}
				}

				if admissible >= 0 {
					to_vertex := edges[admissible].to_vertex
					reverse := edges[admissible].reverse_index
					amount := excess[vertex]
					if edges[admissible].capacity < amount { amount = edges[admissible].capacity }
					edges[admissible].capacity -= amount
					edges[reverse].capacity += amount
					old_excess := excess[to_vertex]
					excess[vertex] -= amount
					excess[to_vertex] += amount
					if old_excess <= 0 && excess[to_vertex] > 0 && !queued[to_vertex] {
						queue[tail] = to_vertex
						tail = (tail + 1) % n
						queue_count += 1
						queued[to_vertex] = true
					}
				} else {
					has_exit := false
					var best_price: i64
					for edge_index := 0; edge_index < arc_count; edge_index += 1 {
						if edges[edge_index].from_vertex != vertex || edges[edge_index].capacity <= 0 { continue }
						to_vertex := edges[edge_index].to_vertex
						candidate := price[to_vertex] - edges[edge_index].cost - epsilon
						if !has_exit || candidate > best_price {
							has_exit = true
							best_price = candidate
						}
					}
					if !has_exit do return -1
					price[vertex] = best_price
				}
			}
		}
		for vertex := 0; vertex < n; vertex += 1 {
			if excess[vertex] != 0 do return -1
		}
	}

	total_cost: i64 = 0
	for index := 0; index < m; index += 1 {
		capacity, cost := input[2+4*index+2], input[2+4*index+3]
		flow := capacity - edges[2*index].capacity
		total_cost += flow * cost
	}
	return total_cost + COST_OFFSET
}
