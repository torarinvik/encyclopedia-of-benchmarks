package tree_path_composite_sum

import "core:c"

MAX_N :: 32
MAX_INPUT :: 5 * MAX_N - 3
MOD :: i64(998244353)

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
	node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
tree_path_composite_sum :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + n + 4 * (n - 1)) do return -1

	vertex_value: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 {
		vertex_value[vertex] = input[1 + vertex]
		if vertex_value[vertex] < 0 || vertex_value[vertex] >= MOD do return -1
	}
	adjacent: [MAX_N * MAX_N]bool
	multiplier, addend: [MAX_N * MAX_N]i64
	dsu_parent, dsu_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		dsu_parent[vertex] = vertex
		dsu_size[vertex] = 1
	}
	offset := 1 + n
	for edge := 0; edge < n - 1; edge += 1 {
		u_value, v_value := input[offset], input[offset + 1]
		b, c_value := input[offset + 2], input[offset + 3]
		offset += 4
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
			u_value == v_value || b < 1 || b >= MOD || c_value < 0 || c_value >= MOD do return -1
		u, v := int(u_value), int(v_value)
		root_u := find_root(&dsu_parent[0], u)
		root_v := find_root(&dsu_parent[0], v)
		if root_u == root_v do return -1
		if dsu_size[root_u] < dsu_size[root_v] {
			temporary := root_u
			root_u = root_v
			root_v = temporary
		}
		dsu_parent[root_v] = root_u
		dsu_size[root_u] += dsu_size[root_v]
		uv, vu := u * MAX_N + v, v * MAX_N + u
		adjacent[uv], adjacent[vu] = true, true
		multiplier[uv], multiplier[vu] = b, b
		addend[uv], addend[vu] = c_value, c_value
	}

	order, stack: [MAX_N]int
	parent: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { parent[vertex] = -2 }
	parent[0] = -1
	top, order_count := 1, 0
	stack[0] = 0
	for top > 0 {
		top -= 1
		u := stack[top]
		order[order_count] = u
		order_count += 1
		for v := 0; v < n; v += 1 {
			cell := u * MAX_N + v
			if adjacent[cell] && v != parent[u] {
				parent[v] = u
				stack[top] = v
				top += 1
			}
		}
	}

	down_sum, up_sum, answer: [MAX_N]i64
	down_count, up_count: [MAX_N]int
	for position := order_count - 1; position >= 0; position -= 1 {
		u := order[position]
		down_sum[u] = vertex_value[u]
		down_count[u] = 1
		for v := 0; v < n; v += 1 {
			cell := u * MAX_N + v
			if adjacent[cell] && parent[v] == u {
				contribution := (multiplier[cell] * down_sum[v] + addend[cell] * i64(down_count[v])) % MOD
				down_sum[u] = (down_sum[u] + contribution) % MOD
				down_count[u] += down_count[v]
			}
		}
	}
	for position := 0; position < order_count; position += 1 {
		u := order[position]
		total_sum, total_count := vertex_value[u], 1
		if parent[u] >= 0 {
			total_sum = (total_sum + up_sum[u]) % MOD
			total_count += up_count[u]
		}
		for v := 0; v < n; v += 1 {
			cell := u * MAX_N + v
			if adjacent[cell] && parent[v] == u {
				total_sum = (total_sum + multiplier[cell] * down_sum[v] +
					addend[cell] * i64(down_count[v])) % MOD
				total_count += down_count[v]
			}
		}
		answer[u] = total_sum
		for v := 0; v < n; v += 1 {
			cell := u * MAX_N + v
			if adjacent[cell] && parent[v] == u {
				contribution := (multiplier[cell] * down_sum[v] + addend[cell] * i64(down_count[v])) % MOD
				outside_sum := (total_sum - contribution + MOD) % MOD
				outside_count := total_count - down_count[v]
				up_sum[v] = (multiplier[cell] * outside_sum + addend[cell] * i64(outside_count)) % MOD
				up_count[v] = outside_count
			}
		}
	}

	required := 8 * n
	if output == nil || capacity < c.size_t(required) do return -2
	for vertex := 0; vertex < n; vertex += 1 { store_le(output, 8 * vertex, answer[vertex]) }
	return i64(required)
}
