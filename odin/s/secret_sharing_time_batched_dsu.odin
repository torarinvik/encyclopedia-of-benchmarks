package secret_sharing_time_batched_dsu

import "core:c"

MAX_N :: 16
MAX_M :: 20

secret_find :: proc(parent: [^]int, node_input: int) -> int {
	node := node_input
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

secret_join :: proc(parent: [^]int, sizes: [^]int, left, right: int) {
	a := secret_find(parent, left)
	b := secret_find(parent, right)
	if a == b do return
	if sizes[a] < sizes[b] { a, b = b, a }
	parent[b] = a
	sizes[a] += sizes[b]
}

@(export)
secret_sharing_time_batched_dsu :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 64 do return -1
	n_value, first_value, m_value := input[0], input[1], input[2]
	if n_value < 2 || n_value > MAX_N || first_value < 1 || first_value >= n_value
		|| m_value < 0 || m_value > MAX_M do return -1
	n, first, m := int(n_value), int(first_value), int(m_value)
	if int(length) != 3+3*m do return -1
	for i := 0; i < m; i += 1 {
		u, v, time := input[3+3*i], input[4+3*i], input[5+3*i]
		if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v || time < 1 || time > 20 do return -1
	}

	parent: [MAX_N]int
	sizes: [MAX_N]int
	for i := 0; i < n; i += 1 { parent[i] = i; sizes[i] = 1 }
	secret_join(&parent[0], &sizes[0], 0, first)
	for time := 1; time <= 20; time += 1 {
		touched: [MAX_N]bool
		for i := 0; i < m; i += 1 {
			u, v := int(input[3+3*i]), int(input[4+3*i])
			if input[5+3*i] == i64(time) {
				secret_join(&parent[0], &sizes[0], u, v)
				touched[u], touched[v] = true, true
			}
		}
		known_root := secret_find(&parent[0], 0)
		for node := 0; node < n; node += 1 {
			if touched[node] && secret_find(&parent[0], node) != known_root {
				parent[node] = node
				sizes[node] = 1
			}
		}
	}
	known_root := secret_find(&parent[0], 0)
	result := i64(0)
	for node := 0; node < n; node += 1 {
		if secret_find(&parent[0], node) == known_root do result |= i64(1) << node
	}
	return result
}
