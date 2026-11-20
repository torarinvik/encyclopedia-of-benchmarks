package wilson_uniform_spanning_tree

import "core:c"

MAX_N :: 8
MAX_EDGES :: 28
WALK_LIMIT :: 64
MAX_INPUT :: 4 + 2 * MAX_EDGES + WALK_LIMIT * (MAX_N - 1)

@(export)
wilson_uniform_spanning_tree :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT + 1 do return -1
	n_raw, m_raw, root_raw := input[0], input[1], input[2]
	if n_raw < 1 || n_raw > MAX_N || m_raw < 0 || m_raw > MAX_EDGES do return -1
	n, m := int(n_raw), int(m_raw)
	if root_raw < 0 || root_raw >= n_raw do return -1
	root := int(root_raw)
	q_at := 3 + 2 * m
	if length <= c.size_t(q_at) do return -1
	q_raw := input[q_at]
	if q_raw < 0 || q_raw > i64(WALK_LIMIT * (n - 1)) do return -1
	q := int(q_raw)
	if length != c.size_t(q_at + 1 + q) do return -1

	neighbors: [MAX_N][MAX_N - 1]int
	degree: [MAX_N]int
	prev_u, prev_v: i64 = -1, -1
	for edge := 0; edge < m; edge += 1 {
		u_raw, v_raw := input[3 + 2 * edge], input[4 + 2 * edge]
		if u_raw < 0 || u_raw >= v_raw || v_raw >= n_raw do return -1
		if edge > 0 && (u_raw < prev_u || (u_raw == prev_u && v_raw <= prev_v)) do return -1
		prev_u, prev_v = u_raw, v_raw
		u, v := int(u_raw), int(v_raw)
		neighbors[u][degree[u]] = v
		degree[u] += 1
		neighbors[v][degree[v]] = u
		degree[v] += 1
	}
	for draw := 0; draw < q; draw += 1 {
		value := input[q_at + 1 + draw]
		if value < 0 || value > MAX_N - 2 do return -1
	}

	seen: [MAX_N]bool
	queue: [MAX_N]int
	head, tail := 0, 0
	seen[root] = true
	queue[tail] = root
	tail += 1
	for head < tail {
		at := queue[head]
		head += 1
		for k := 0; k < degree[at]; k += 1 {
			to := neighbors[at][k]
			if !seen[to] {
				seen[to] = true
				queue[tail] = to
				tail += 1
			}
		}
	}
	for vertex := 0; vertex < n; vertex += 1 { if !seen[vertex] do return -1 }

	in_tree: [MAX_N]bool
	successor: [MAX_N]int
	for i := 0; i < MAX_N; i += 1 { successor[i] = -1 }
	in_tree[root] = true
	cursor := 0
	for start := 0; start < n; start += 1 {
		if in_tree[start] do continue
		current, steps := start, 0
		for !in_tree[current] {
			if steps >= WALK_LIMIT || cursor >= q do return -1
			choice := int(input[q_at + 1 + cursor])
			if choice >= degree[current] do return -1
			successor[current] = neighbors[current][choice]
			current = successor[current]
			cursor += 1
			steps += 1
		}
		current = start
		for !in_tree[current] { in_tree[current] = true; current = successor[current] }
	}
	if cursor != q do return -1

	required := 16 * (n - 1)
	if (required > 0 && output == nil) || capacity < c.size_t(required) do return -2
	offset := 0
	for child := 0; child < n; child += 1 {
		if child == root do continue
		write_i64_le(output, offset, i64(child)); offset += 8
		write_i64_le(output, offset, i64(successor[child])); offset += 8
	}
	return i64(required)
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}
