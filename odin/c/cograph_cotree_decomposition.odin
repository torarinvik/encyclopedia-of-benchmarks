package cograph_cotree_decomposition

import "core:c"

N :: 12
M :: 66
PARSEABLE :: 135
OUTPUT :: 47

ct_components :: proc "contextless" (mask: u16, adjacency: [N]u16,
		complement: bool, parts: ^[N]u16) -> int {
	remaining := mask
	count := 0
	for root := 0; root < N; root += 1 {
		root_bit := u16(1) << u16(root)
		if remaining & root_bit == 0 do continue
		reached := root_bit
		queue: [N]int
		head, tail := 0, 1
		queue[0] = root
		for head < tail {
			vertex := queue[head]
			head += 1
			neighbors := adjacency[vertex] & mask
			if complement do neighbors = mask & ~adjacency[vertex] & ~(u16(1) << u16(vertex))
			fresh := neighbors & ~reached
			for next := 0; next < N; next += 1 {
				bit := u16(1) << u16(next)
				if fresh & bit != 0 {
					fresh &= ~bit
					reached |= bit
					queue[tail] = next
					tail += 1
				}
			}
		}
		parts[count] = reached
		count += 1
		remaining &= ~reached
	}
	return count
}

ct_emit :: proc "contextless" (mask: u16, adjacency: [N]u16,
		output: ^[OUTPUT]u8, position: ^int) -> bool {
	if mask & (mask - 1) == 0 {
		vertex := 0
		for mask & (u16(1) << u16(vertex)) == 0 { vertex += 1 }
		output[position^] = 0
		output[position^ + 1] = u8(vertex)
		position^ += 2
		return true
	}
	parts: [N]u16
	count := ct_components(mask, adjacency, false, &parts)
	kind := u8(1)
	if count == 1 {
		count = ct_components(mask, adjacency, true, &parts)
		kind = 2
		if count <= 1 do return false
	}
	output[position^] = kind
	output[position^ + 1] = u8(count)
	position^ += 2
	for i := 0; i < count; i += 1 {
		if !ct_emit(parts[i], adjacency, output, position) do return false
	}
	return true
}

@(export)
cograph_cotree_decomposition :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(PARSEABLE) do return -1
	n_value, m_value := input[0], input[1]
	if n_value < 1 || n_value > N || m_value < 0 || m_value > M || m_value > n_value*(n_value-1)/2 ||
		length != c.size_t(2 + 2*m_value) do return -1
	n, m := int(n_value), int(m_value)
	adjacency: [N]u16
	for edge := 0; edge < m; edge += 1 {
		u_value, v_value := input[2 + 2*edge], input[3 + 2*edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		ub, vb := u16(1) << u16(u), u16(1) << u16(v)
		if adjacency[u] & vb != 0 do return -1
		adjacency[u] |= vb
		adjacency[v] |= ub
	}
	staged: [OUTPUT]u8
	position := 1
	all := (u16(1) << u16(n)) - 1
	if ct_emit(all, adjacency, &staged, &position) {
		staged[0] = 1
	} else {
		staged[0] = 0
		position = 1
	}
	if output == nil || capacity < c.size_t(position) do return -2
	for i := 0; i < position; i += 1 do output[i] = staged[i]
	return i64(position)
}
