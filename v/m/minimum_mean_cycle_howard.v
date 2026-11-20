module minimum_mean_cycle_howard

const max_n = 8
const max_m = 16
const max_input_length = 51
const output_bytes = 16

struct Edge {
	from int
	to int
	weight i64
}

fn store_i64_le(mut output []u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn gcd_positive(a_value i64, b_value i64) i64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn compare_ratio(a_num i64, a_den i64, b_num i64, b_den i64) int {
	left := a_num * b_den
	right := b_num * a_den
	if left < right { return -1 }
	if left > right { return 1 }
	return 0
}

fn all_reachable(n int, adjacent [max_n * max_n]bool, reverse bool) bool {
	mut seen := [max_n]bool{}
	mut queue := [max_n]int{}
	mut head := 0
	mut tail := 1
	seen[0] = true
	queue[0] = 0
	for head < tail {
		u := queue[head]
		head++
		for v in 0 .. n {
			slot := if reverse { v * max_n + u } else { u * max_n + v }
			if adjacent[slot] && !seen[v] {
				seen[v] = true
				queue[tail] = v
				tail++
			}
		}
	}
	for v in 0 .. n {
		if !seen[v] { return false }
	}
	return true
}

fn compare_appraisal(a_edge int, b_edge int, edges [max_m]Edge,
	value_num [max_n]i64, value_den [max_n]i64, bias_num [max_n]i64) int {
	a := edges[a_edge]
	b := edges[b_edge]
	comparison := compare_ratio(value_num[a.to], value_den[a.to], value_num[b.to], value_den[b.to])
	if comparison != 0 { return comparison }
	a_bias := a.weight * value_den[a.to] - value_num[a.to] + bias_num[a.to]
	b_bias := b.weight * value_den[b.to] - value_num[b.to] + bias_num[b.to]
	return compare_ratio(a_bias, value_den[a.to], b_bias, value_den[b.to])
}

fn evaluate_policy(n int, edges [max_m]Edge, policy [max_n]int,
	mut value_num [max_n]i64, mut value_den [max_n]i64, mut bias_num [max_n]i64) {
	mut assigned := [max_n]bool{}
	for start in 0 .. n {
		if assigned[start] { continue }
		mut local_position := [max_n]int{}
		for vertex in 0 .. max_n { local_position[vertex] = -1 }
		mut path := [max_n]int{}
	mut path_length := 0
	mut vertex := start
		for !assigned[vertex] && local_position[vertex] < 0 {
			local_position[vertex] = path_length
			path[path_length] = vertex
			path_length++
			vertex = edges[policy[vertex]].to
		}

		mut prefix_length := path_length
		if !assigned[vertex] {
			cycle_start := local_position[vertex]
			cycle_length := path_length - cycle_start
			mut cycle_weight := i64(0)
			mut head_position := cycle_start
			for index in cycle_start .. path_length {
				member := path[index]
				cycle_weight += edges[policy[member]].weight
				if path[index] < path[head_position] { head_position = index }
			}
			mut absolute_weight := cycle_weight
			if absolute_weight < 0 { absolute_weight = -absolute_weight }
			divisor := gcd_positive(absolute_weight, i64(cycle_length))
			mean_num := cycle_weight / divisor
			mean_den := i64(cycle_length) / divisor
			head := path[head_position]
			for index in cycle_start .. path_length {
				member := path[index]
				value_num[member] = mean_num
				value_den[member] = mean_den
				assigned[member] = true
			}

			bias_num[head] = 0
			mut current_position := head_position
			for {
				previous_position := if current_position == cycle_start { path_length - 1 } else { current_position - 1 }
				previous := path[previous_position]
				if previous == head { break }
				bias_num[previous] = edges[policy[previous]].weight * mean_den - mean_num + bias_num[path[current_position]]
				current_position = previous_position
			}
			prefix_length = cycle_start
		}

		mut prefix_position := prefix_length
		for prefix_position > 0 {
			prefix_position--
			u := path[prefix_position]
			successor := edges[policy[u]].to
			value_num[u] = value_num[successor]
			value_den[u] = value_den[successor]
			bias_num[u] = edges[policy[u]].weight * value_den[successor] - value_num[successor] + bias_num[successor]
			assigned[u] = true
		}
	}
}

@[export: 'minimum_mean_cycle_howard']
pub fn minimum_mean_cycle_howard(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > max_input_length { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > i64(max_n) || m_value < 1 || m_value > i64(max_m) { return -1 }
		n, m := int(n_value), int(m_value)
		if m > n * n || input_length != usize(2 + 3 * m) { return -1 }

		mut edges := [max_m]Edge{}
		mut adjacent := [max_n * max_n]bool{}
		mut outgoing := [max_n * max_m]int{}
		mut degree := [max_n]int{}
		mut policy := [max_n]int{}
		for edge_index in 0 .. m {
			from_value, to_value, weight := input[2 + 3 * edge_index], input[3 + 3 * edge_index], input[4 + 3 * edge_index]
			if from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value || weight < -1000 || weight > 1000 { return -1 }
			from, to := int(from_value), int(to_value)
			slot := from * max_n + to
			if adjacent[slot] { return -1 }
			adjacent[slot] = true
			edges[edge_index] = Edge{from, to, weight}
			outgoing[from * max_m + degree[from]] = edge_index
			degree[from]++
			if degree[from] == 1 { policy[from] = edge_index }
		}
		if !all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true) { return -1 }
		if output == nil || output_capacity < output_bytes { return -2 }

		mut policy_limit := 1
		for vertex in 0 .. n { policy_limit *= degree[vertex] }
		mut value_num := [max_n]i64{}
		mut value_den := [max_n]i64{}
		mut bias_num := [max_n]i64{}
		for vertex in 0 .. max_n { value_den[vertex] = 1 }
		mut converged := false
		for _ in 0 .. policy_limit {
			evaluate_policy(n, edges, policy, mut value_num, mut value_den, mut bias_num)
			mut improved := policy
			mut changed := false
			for vertex in 0 .. n {
				mut best := policy[vertex]
				for index in 0 .. degree[vertex] {
					candidate := outgoing[vertex * max_m + index]
					if compare_appraisal(candidate, best, edges, value_num, value_den, bias_num) < 0 { best = candidate }
				}
				improved[vertex] = best
				if best != policy[vertex] { changed = true }
			}
			if !changed {
				converged = true
				break
			}
			policy = improved
		}
		if !converged { return -1 }

		mut best_vertex := 0
		for vertex in 1 .. n {
			if compare_ratio(value_num[vertex], value_den[vertex], value_num[best_vertex], value_den[best_vertex]) < 0 {
				best_vertex = vertex
			}
		}
		mut answer_num := value_num[best_vertex]
		mut answer_den := value_den[best_vertex]
		mut absolute_answer := answer_num
		if absolute_answer < 0 { absolute_answer = -absolute_answer }
		divisor := gcd_positive(absolute_answer, answer_den)
		answer_num /= divisor
		answer_den /= divisor

		mut staged := [output_bytes]u8{}
		store_i64_le(mut staged[..], 0, answer_num)
		store_i64_le(mut staged[..], 8, answer_den)
		for byte in 0 .. output_bytes { output[byte] = staged[byte] }
		return output_bytes
	}
}
