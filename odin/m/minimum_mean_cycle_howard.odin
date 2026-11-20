package minimum_mean_cycle_howard

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 16
MAX_INPUT_LENGTH :: 51
OUTPUT_BYTES :: 16

Edge :: struct { from_vertex: int, to_vertex: int, weight: i64 }

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

gcd_positive :: proc(a_value, b_value: i64) -> i64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

compare_ratio :: proc(a_num, a_den, b_num, b_den: i64) -> int {
	left, right := a_num*b_den, b_num*a_den
	if left < right do return -1
	if left > right do return 1
	return 0
}

all_reachable :: proc(n: int, adjacent: [MAX_VERTICES * MAX_VERTICES]bool, reverse: bool) -> bool {
	var seen: [MAX_VERTICES]bool
	var queue: [MAX_VERTICES]int
	head, tail := 0, 1
	seen[0] = true
	queue[0] = 0
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < n; v += 1 {
			slot := if reverse { v*MAX_VERTICES+u } else { u*MAX_VERTICES+v }
			if adjacent[slot] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail += 1
			}
		}
	}
	for v := 0; v < n; v += 1 { if !seen[v] do return false }
	return true
}

compare_appraisal :: proc(a_edge, b_edge: int, edges: ^[MAX_EDGES]Edge,
		value_num: ^[MAX_VERTICES]i64, value_den: ^[MAX_VERTICES]i64,
		bias_num: ^[MAX_VERTICES]i64) -> int {
	a, b := edges[a_edge], edges[b_edge]
	comparison := compare_ratio(value_num[a.to_vertex], value_den[a.to_vertex],
		value_num[b.to_vertex], value_den[b.to_vertex])
	if comparison != 0 do return comparison
	a_bias := a.weight*value_den[a.to_vertex] - value_num[a.to_vertex] + bias_num[a.to_vertex]
	b_bias := b.weight*value_den[b.to_vertex] - value_num[b.to_vertex] + bias_num[b.to_vertex]
	return compare_ratio(a_bias, value_den[a.to_vertex], b_bias, value_den[b.to_vertex])
}

evaluate_policy :: proc(n: int, edges: ^[MAX_EDGES]Edge, policy: ^[MAX_VERTICES]int,
		value_num: ^[MAX_VERTICES]i64, value_den: ^[MAX_VERTICES]i64,
		bias_num: ^[MAX_VERTICES]i64) {
	var assigned: [MAX_VERTICES]bool
	for start := 0; start < n; start += 1 {
		if assigned[start] do continue
		var local_position: [MAX_VERTICES]int
		for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { local_position[vertex] = -1 }
		var path: [MAX_VERTICES]int
		path_length := 0
		vertex := start
		for !assigned[vertex] && local_position[vertex] < 0 {
			local_position[vertex] = path_length
			path[path_length] = vertex
			path_length += 1
			vertex = edges[policy[vertex]].to_vertex
		}

		prefix_length := path_length
		if !assigned[vertex] {
			cycle_start := local_position[vertex]
			cycle_length := path_length - cycle_start
			cycle_weight: i64 = 0
			head_position := cycle_start
			for index := cycle_start; index < path_length; index += 1 {
				member := path[index]
				cycle_weight += edges[policy[member]].weight
				if path[index] < path[head_position] { head_position = index }
			}
			absolute_weight := cycle_weight
			if absolute_weight < 0 { absolute_weight = -absolute_weight }
			divisor := gcd_positive(absolute_weight, i64(cycle_length))
			mean_num, mean_den := cycle_weight/divisor, i64(cycle_length)/divisor
			head := path[head_position]
			for index := cycle_start; index < path_length; index += 1 {
				member := path[index]
				value_num[member] = mean_num
				value_den[member] = mean_den
				assigned[member] = true
			}

			bias_num[head] = 0
			current_position := head_position
			for {
				previous_position := current_position - 1
				if current_position == cycle_start { previous_position = path_length - 1 }
				previous := path[previous_position]
				if previous == head do break
				bias_num[previous] = edges[policy[previous]].weight*mean_den - mean_num + bias_num[path[current_position]]
				current_position = previous_position
			}
			prefix_length = cycle_start
		}

		prefix_position := prefix_length
		for prefix_position > 0 {
			prefix_position -= 1
			u := path[prefix_position]
			successor := edges[policy[u]].to_vertex
			value_num[u] = value_num[successor]
			value_den[u] = value_den[successor]
			bias_num[u] = edges[policy[u]].weight*value_den[successor] - value_num[successor] + bias_num[successor]
			assigned[u] = true
		}
	}
}

@(export)
minimum_mean_cycle_howard :: proc "c" (input: [^]i64, input_length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 1 || m_value > MAX_EDGES do return -1
	n, m := int(n_value), int(m_value)
	if m > n*n || int(input_length) != 2+3*m do return -1

	var edges: [MAX_EDGES]Edge
	var adjacent: [MAX_VERTICES * MAX_VERTICES]bool
	var outgoing: [MAX_VERTICES * MAX_EDGES]int
	var degree: [MAX_VERTICES]int
	var policy: [MAX_VERTICES]int
	for edge_index := 0; edge_index < m; edge_index += 1 {
		from_value, to_value, weight := input[2+3*edge_index], input[3+3*edge_index], input[4+3*edge_index]
		if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value || weight < -1000 || weight > 1000 do return -1
		from_vertex, to_vertex := int(from_value), int(to_value)
		slot := from_vertex*MAX_VERTICES + to_vertex
		if adjacent[slot] do return -1
		adjacent[slot] = true
		edges[edge_index] = Edge{from_vertex, to_vertex, weight}
		outgoing[from_vertex*MAX_EDGES+degree[from_vertex]] = edge_index
		degree[from_vertex] += 1
		if degree[from_vertex] == 1 { policy[from_vertex] = edge_index }
	}
	if !all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true) do return -1
	if output == nil || output_capacity < OUTPUT_BYTES do return -2

	policy_limit := 1
	for vertex := 0; vertex < n; vertex += 1 { policy_limit *= degree[vertex] }
	var value_num: [MAX_VERTICES]i64
	var value_den: [MAX_VERTICES]i64
	var bias_num: [MAX_VERTICES]i64
	for vertex := 0; vertex < MAX_VERTICES; vertex += 1 { value_den[vertex] = 1 }
	converged := false
	for iteration := 0; iteration < policy_limit; iteration += 1 {
		evaluate_policy(n, &edges, &policy, &value_num, &value_den, &bias_num)
		improved := policy
		changed := false
		for vertex := 0; vertex < n; vertex += 1 {
			best := policy[vertex]
			for index := 0; index < degree[vertex]; index += 1 {
				candidate := outgoing[vertex*MAX_EDGES+index]
				if compare_appraisal(candidate, best, &edges, &value_num, &value_den, &bias_num) < 0 { best = candidate }
			}
			improved[vertex] = best
			if best != policy[vertex] { changed = true }
		}
		if !changed { converged = true; break }
		policy = improved
	}
	if !converged do return -1

	best_vertex := 0
	for vertex := 1; vertex < n; vertex += 1 {
		if compare_ratio(value_num[vertex], value_den[vertex], value_num[best_vertex], value_den[best_vertex]) < 0 { best_vertex = vertex }
	}
	answer_num, answer_den := value_num[best_vertex], value_den[best_vertex]
	abs_answer := answer_num
	if abs_answer < 0 { abs_answer = -abs_answer }
	divisor := gcd_positive(abs_answer, answer_den)
	answer_num /= divisor
	answer_den /= divisor
	var staged: [OUTPUT_BYTES]u8
	store_i64_le(&staged[0], 0, answer_num)
	store_i64_le(&staged[0], 8, answer_den)
	for byte := 0; byte < OUTPUT_BYTES; byte += 1 { output[byte] = staged[byte] }
	return OUTPUT_BYTES
}
