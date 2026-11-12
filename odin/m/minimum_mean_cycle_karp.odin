package minimum_mean_cycle_karp

import "core:c"

MAX_N :: 8
MAX_M :: 16
MAX_INPUT :: 51
OUTPUT_BYTES :: 16

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

ratio_less :: proc(a_num, a_den, b_num, b_den: i64) -> bool {
	return a_num * b_den < b_num * a_den
}

gcd_positive :: proc(a_value, b_value: i64) -> i64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

all_reachable :: proc(n: int, adjacent: [64]bool, reverse: bool) -> bool {
	seen: [8]bool = false
	queue: [8]int = 0
	head, tail := 0, 1
	seen[0] = true
	for head < tail {
		u := queue[head]
		head += 1
		for v := 0; v < n; v += 1 {
			slot := if reverse do v * 8 + u else u * 8 + v
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

@(export)
minimum_mean_cycle_karp :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || m_value < 1 || m_value > MAX_M do return -1
	n, m := int(n_value), int(m_value)
	if m > n * n || int(length) != 2 + 3*m do return -1

	edge_from: [16]int = 0
	edge_to: [16]int = 0
	edge_weight: [16]i64 = 0
	adjacent: [64]bool = false
	for edge := 0; edge < m; edge += 1 {
		u_value, v_value, weight := input[2+3*edge], input[3+3*edge], input[4+3*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || weight < -1000 || weight > 1000 do return -1
		u, v := int(u_value), int(v_value)
		slot := u * 8 + v
		if adjacent[slot] do return -1
		adjacent[slot] = true
		edge_from[edge], edge_to[edge], edge_weight[edge] = u, v, weight
	}
	if !all_reachable(n, adjacent, false) || !all_reachable(n, adjacent, true) do return -1
	if output == nil || output_capacity < OUTPUT_BYTES do return -2

	cost: [72]i64 = 0
	reachable: [72]bool = false
	reachable[0] = true
	for k := 1; k <= n; k += 1 {
		for edge := 0; edge < m; edge += 1 {
			u, v := edge_from[edge], edge_to[edge]
			previous, current := (k-1)*8+u, k*8+v
			if !reachable[previous] do continue
			candidate := cost[previous] + edge_weight[edge]
			if !reachable[current] || candidate < cost[current] {
				reachable[current] = true
				cost[current] = candidate
			}
		}
	}

	have_answer := false
	answer_num, answer_den: i64 = 0, 1
	for v := 0; v < n; v += 1 {
		if !reachable[n*8+v] do continue
		have_local := false
		local_num, local_den: i64 = 0, 1
		for k := 0; k < n; k += 1 {
			slot := k*8+v
			if !reachable[slot] do continue
			numerator, denominator := cost[n*8+v]-cost[slot], i64(n-k)
			if !have_local || ratio_less(local_num, local_den, numerator, denominator) {
				local_num, local_den = numerator, denominator
				have_local = true
			}
		}
		if have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den)) {
			answer_num, answer_den = local_num, local_den
			have_answer = true
		}
	}
	if !have_answer do return -1
	abs_num := if answer_num < 0 do -answer_num else answer_num
	divisor := gcd_positive(abs_num, answer_den)
	answer_num /= divisor
	answer_den /= divisor
	staged: [16]u8 = 0
	store_i64_le(&staged[0], 0, answer_num)
	store_i64_le(&staged[0], 8, answer_den)
	for byte := 0; byte < 16; byte += 1 { output[byte] = staged[byte] }
	return OUTPUT_BYTES
}
