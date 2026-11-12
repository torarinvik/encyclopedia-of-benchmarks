package undirected_chinese_postman

import "core:c"

MAX_N :: 8
MAX_M :: 12
INF :: i64(1_000_000_000)

@(export)
undirected_chinese_postman :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 38 do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M do return -1
	n, m := int(input[0]), int(input[1])
	if length != c.size_t(2 + 3 * m) do return -1
	if n == 1 {
		if m == 0 do return 0
		return -1
	}
	if m < n - 1 do return -1
	distance: [MAX_N * MAX_N]i64
	seen: [MAX_N * MAX_N]bool
	degree: [MAX_N]int
	for u := 0; u < n; u += 1 {
		for v := 0; v < n; v += 1 { distance[u * MAX_N + v] = if u == v { 0 } else { INF } }
	}
	total_weight := i64(0)
	for edge := 0; edge < m; edge += 1 {
		u_value, v_value, weight := input[2 + 3 * edge], input[3 + 3 * edge], input[4 + 3 * edge]
		if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value || weight < 1 || weight > 1000 do return -1
		u, v := int(u_value), int(v_value)
		if seen[u * MAX_N + v] do return -1
		seen[u * MAX_N + v] = true
		seen[v * MAX_N + u] = true
		distance[u * MAX_N + v] = weight
		distance[v * MAX_N + u] = weight
		degree[u] += 1
		degree[v] += 1
		total_weight += weight
	}
	for middle := 0; middle < n; middle += 1 {
		for source := 0; source < n; source += 1 {
			for target := 0; target < n; target += 1 {
				candidate := distance[source * MAX_N + middle] + distance[middle * MAX_N + target]
				if candidate < distance[source * MAX_N + target] do distance[source * MAX_N + target] = candidate
			}
		}
	}
	for vertex := 0; vertex < n; vertex += 1 do if distance[vertex] >= INF do return -1
	odd: [MAX_N]int
	odd_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		if degree[vertex] & 1 != 0 { odd[odd_count] = vertex; odd_count += 1 }
	}
	state_count := 1 << odd_count
	pairing: [1 << MAX_N]i64
	for mask := 0; mask < state_count; mask += 1 do pairing[mask] = INF
	pairing[0] = 0
	for mask := 1; mask < state_count; mask += 1 {
		first := 0
		for mask & (1 << first) == 0 { first += 1 }
		first_bit := 1 << first
		for partner := first + 1; partner < odd_count; partner += 1 {
			partner_bit := 1 << partner
			if mask & partner_bit == 0 do continue
			remaining := mask ^ first_bit ^ partner_bit
			candidate := distance[odd[first] * MAX_N + odd[partner]] + pairing[remaining]
			if candidate < pairing[mask] do pairing[mask] = candidate
		}
	}
	return total_weight + pairing[state_count - 1]
}
