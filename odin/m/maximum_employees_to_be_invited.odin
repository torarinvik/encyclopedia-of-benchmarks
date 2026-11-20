package maximum_employees_to_be_invited

import "core:c"

MAX_N :: 8
MAX_INPUT :: 10

@(export)
maximum_employees_to_be_invited :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 2 || n_value > MAX_N || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	favorite: [MAX_N]i64
	indegree: [MAX_N]i64
	chain: [MAX_N]i64
	queue: [MAX_N]int
	visited: [MAX_N]bool
	for i := 0; i < n; i += 1 {
		target := input[i + 1]
		if target < 0 || target >= n_value || target == i64(i) do return -1
		favorite[i] = target
		indegree[int(target)] += 1
		chain[i] = 1
	}
	head, tail := 0, 0
	for i := 0; i < n; i += 1 {
		if indegree[i] == 0 { queue[tail] = i; tail += 1 }
	}
	for head < tail {
		node := queue[head]; head += 1
		target := int(favorite[node])
		if chain[node] + 1 > chain[target] do chain[target] = chain[node] + 1
		indegree[target] -= 1
		if indegree[target] == 0 { queue[tail] = target; tail += 1 }
	}
	pair_total, longest_cycle := i64(0), i64(0)
	for start := 0; start < n; start += 1 {
		if indegree[start] == 0 || visited[start] do continue
		node, first, second := start, 0, 0
		cycle_length := 0
		for !visited[node] {
			visited[node] = true
			if cycle_length == 0 { first = node } else if cycle_length == 1 { second = node }
			cycle_length += 1
			node = int(favorite[node])
		}
		if cycle_length == 2 { pair_total += chain[first] + chain[second] }
		if i64(cycle_length) > longest_cycle { longest_cycle = i64(cycle_length) }
	}
	if pair_total > longest_cycle { return pair_total }
	return longest_cycle
}
