package bst_interleave_bound

import "core:c"

MAX_NODES :: 8
MAX_ACCESSES :: 16
MAX_INPUT :: 36

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
}

bst_interleave_bound :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_raw, root_raw := input[0], input[1]
	if n_raw < 1 || n_raw > MAX_NODES || root_raw < 0 || root_raw >= n_raw do return -1
	n, root := int(n_raw), int(root_raw)
	left: [MAX_NODES]int
	right: [MAX_NODES]int
	parent: [MAX_NODES]int
	parent_count: [MAX_NODES]int
	for node := 0; node < MAX_NODES; node += 1 { left[node] = -1; right[node] = -1; parent[node] = -1 }
	position := 2
	for node := 0; node < n; node += 1 {
		if position + 2 > int(length) do return -1
		l, r := int(input[position]), int(input[position + 1])
		position += 2
		if l < -1 || l >= n || r < -1 || r >= n || l == node || r == node || (l >= 0 && l == r) do return -1
		left[node] = l; right[node] = r
		if l >= 0 { parent_count[l] += 1; parent[l] = node }
		if r >= 0 { parent_count[r] += 1; parent[r] = node }
	}
	if parent_count[root] != 0 do return -1
	for node := 0; node < n; node += 1 { if node != root && parent_count[node] != 1 do return -1 }
	if position >= int(length) do return -1
	m_raw := input[position]
	position += 1
	if m_raw < 0 || m_raw > MAX_ACCESSES || int(length) != position + int(m_raw) do return -1
	m := int(m_raw)
	accesses: [MAX_ACCESSES]int
	for i := 0; i < m; i += 1 {
		key := input[position]; position += 1
		if key < 0 || key >= n_raw do return -1
		accesses[i] = int(key)
	}

	stack_node: [MAX_NODES]int
	stack_low: [MAX_NODES]int
	stack_high: [MAX_NODES]int
	visited: [MAX_NODES]bool
	stack_size, visited_count := 1, 0
	stack_node[0] = root; stack_low[0] = -1; stack_high[0] = n
	for stack_size > 0 {
		stack_size -= 1
		node, low, high := stack_node[stack_size], stack_low[stack_size], stack_high[stack_size]
		if visited[node] || node <= low || node >= high do return -1
		visited[node] = true; visited_count += 1
		if left[node] >= 0 {
			stack_node[stack_size] = left[node]; stack_low[stack_size] = low; stack_high[stack_size] = node
			stack_size += 1
		}
		if right[node] >= 0 {
			stack_node[stack_size] = right[node]; stack_low[stack_size] = node; stack_high[stack_size] = high
			stack_size += 1
		}
	}
	if visited_count != n do return -1

	bound: i64 = 0
	for pivot := 0; pivot < n; pivot += 1 {
		previous := -1
		for i := 0; i < m; i += 1 {
			key := accesses[i]
			ancestor := key
			for ancestor >= 0 && ancestor != pivot { ancestor = parent[ancestor] }
			if ancestor == pivot {
				side := 1
				if key <= pivot do side = 0
				if previous >= 0 && side != previous do bound += 1
				previous = side
			}
		}
	}
	if output == nil || capacity < 8 do return -2
	staged: [8]u8
	store_i64_le(&staged[0], bound)
	for byte := 0; byte < 8; byte += 1 { output[byte] = staged[byte] }
	return 8
}
