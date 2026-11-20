module minimum_cost_circulation_cost_scaling

const max_n = 8
const max_m = 10
const max_input_length = 43
const max_arcs = 2 * max_m
const cost_offset = i64(81)

struct ResidualArc {
mut:
	from int
	to int
	reverse int
	capacity i64
	cost i64
}

@[export: 'minimum_cost_circulation_cost_scaling']
pub fn minimum_cost_circulation_cost_scaling(input &i64, length usize) i64 {
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

		mut edges := [max_arcs]ResidualArc{}
		mut max_scaled_cost := i64(0)
		for index in 0 .. m {
			offset := 2 + 4 * index
			from_arg, to_arg := input[offset], input[offset + 1]
			capacity, cost := input[offset + 2], input[offset + 3]
			if from_arg < 0 || from_arg >= n_arg || to_arg < 0 || to_arg >= n_arg ||
				capacity < 0 || capacity > 2 || cost < -4 || cost > 4 {
				return -1
			}
			from, to := int(from_arg), int(to_arg)
			scaled_cost := cost * i64(n + 1)
			forward, reverse := 2 * index, 2 * index + 1
			edges[forward] = ResidualArc{from, to, reverse, capacity, scaled_cost}
			edges[reverse] = ResidualArc{to, from, forward, 0, -scaled_cost}
			magnitude := scaled_cost
			if magnitude < 0 {
				magnitude = -magnitude
			}
			if magnitude > max_scaled_cost {
				max_scaled_cost = magnitude
			}
		}

		mut epsilon := i64(1)
		for epsilon < max_scaled_cost {
			epsilon *= 2
		}
		mut price := [max_n]i64{}
		arc_count := 2 * m
		for epsilon > 1 {
			epsilon /= 2
			mut excess := [max_n]i64{}

			for edge_index in 0 .. arc_count {
				if edges[edge_index].capacity <= 0 {
					continue
				}
				from, to := edges[edge_index].from, edges[edge_index].to
				reduced_cost := edges[edge_index].cost + price[from] - price[to]
				if reduced_cost < 0 {
					amount := edges[edge_index].capacity
					edges[edge_index].capacity = 0
					edges[edges[edge_index].reverse].capacity += amount
					excess[from] -= amount
					excess[to] += amount
				}
			}

			mut queue := [max_n]int{}
			mut queued := [max_n]bool{}
			mut head, tail, queue_count := 0, 0, 0
			for vertex in 0 .. n {
				if excess[vertex] > 0 {
					queue[tail] = vertex
					tail = (tail + 1) % n
					queue_count++
					queued[vertex] = true
				}
			}

			for queue_count > 0 {
				vertex := queue[head]
				head = (head + 1) % n
				queue_count--
				queued[vertex] = false
				for excess[vertex] > 0 {
					mut admissible := -1
					for edge_index in 0 .. arc_count {
						if edges[edge_index].from != vertex || edges[edge_index].to == vertex ||
							edges[edge_index].capacity <= 0 {
							continue
						}
						to := edges[edge_index].to
						if edges[edge_index].cost + price[vertex] - price[to] < 0 {
							admissible = edge_index
							break
						}
					}

					if admissible >= 0 {
						to, reverse := edges[admissible].to, edges[admissible].reverse
						mut amount := excess[vertex]
						if edges[admissible].capacity < amount {
							amount = edges[admissible].capacity
						}
						edges[admissible].capacity -= amount
						edges[reverse].capacity += amount
						old_excess := excess[to]
						excess[vertex] -= amount
						excess[to] += amount
						if old_excess <= 0 && excess[to] > 0 && !queued[to] {
							queue[tail] = to
							tail = (tail + 1) % n
							queue_count++
							queued[to] = true
						}
					} else {
						mut has_exit := false
						mut best_price := i64(0)
						for edge_index in 0 .. arc_count {
							if edges[edge_index].from != vertex || edges[edge_index].capacity <= 0 {
								continue
							}
							to := edges[edge_index].to
							candidate := price[to] - edges[edge_index].cost - epsilon
							if !has_exit || candidate > best_price {
								has_exit = true
								best_price = candidate
							}
						}
						if !has_exit {
							return -1
						}
						price[vertex] = best_price
					}
				}
			}
			for vertex in 0 .. n {
				if excess[vertex] != 0 {
					return -1
				}
			}
		}

		mut total_cost := i64(0)
		for index in 0 .. m {
			capacity, cost := input[2 + 4 * index + 2], input[2 + 4 * index + 3]
			flow := capacity - edges[2 * index].capacity
			total_cost += flow * cost
		}
		return total_cost + cost_offset
	}
}
