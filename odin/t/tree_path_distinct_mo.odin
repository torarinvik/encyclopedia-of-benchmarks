package tree_path_distinct_mo

import "core:c"

MAX_N :: 32
MAX_Q :: 32
MAX_INPUT :: 3 * MAX_N + 2 * MAX_Q

Query :: struct {
	left, right, id, block, right_key, extra: int,
}

find_root :: proc "contextless" (parent: []int, item: int) -> int {
	node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

query_less :: proc "contextless" (a, b: Query) -> bool {
	if a.block != b.block do return a.block < b.block
	if a.right_key != b.right_key do return a.right_key < b.right_key
	return a.id < b.id
}

sift_down :: proc "contextless" (values: []Query, root_start, end: int) {
	root := root_start
	for root * 2 + 1 < end {
		child := root * 2 + 1
		largest := root
		if query_less(values[largest], values[child]) do largest = child
		if child + 1 < end && query_less(values[largest], values[child + 1]) do largest = child + 1
		if largest == root do return
		temporary := values[root]
		values[root] = values[largest]
		values[largest] = temporary
		root = largest
	}
}

sort_queries :: proc "contextless" (values: []Query, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, count)
	}
	end := count
	for end > 1 {
		end -= 1
		temporary := values[0]
		values[0] = values[end]
		values[end] = temporary
		sift_down(values, 0, end)
	}
}

lca :: proc "contextless" (a_raw, b_raw: int, parent, depth: []int) -> int {
	a, b := a_raw, b_raw
	for depth[a] > depth[b] { a = parent[a] }
	for depth[b] > depth[a] { b = parent[b] }
	for a != b { a = parent[a]; b = parent[b] }
	return a
}

toggle :: proc "contextless" (vertex: int, color_id: []int, counts: []int,
	active: []bool, distinct: ^int) {
	color := color_id[vertex]
	if active[vertex] {
		active[vertex] = false
		counts[color] -= 1
		if counts[color] == 0 do distinct^ -= 1
	} else {
		active[vertex] = true
		if counts[color] == 0 do distinct^ += 1
		counts[color] += 1
	}
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
tree_path_distinct_mo :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT + 1 do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(3 * n + 2 * q) do return -1

	colors: [MAX_N]i64
	for vertex := 0; vertex < n; vertex += 1 { colors[vertex] = input[2 + vertex] }
	adjacent: [MAX_N * MAX_N]bool
	dsu_parent, dsu_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { dsu_parent[vertex] = vertex; dsu_size[vertex] = 1 }
	offset := 2 + n
	for _ := 0; _ < n - 1; _ += 1 {
		u_value, v_value := input[offset], input[offset + 1]
		offset += 2
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u, v := int(u_value), int(v_value)
		root_u := find_root(dsu_parent[:], u)
		root_v := find_root(dsu_parent[:], v)
		if root_u == root_v do return -1
		if dsu_size[root_u] < dsu_size[root_v] { temporary := root_u; root_u = root_v; root_v = temporary }
		dsu_parent[root_v] = root_u
		dsu_size[root_u] += dsu_size[root_v]
		adjacent[u * MAX_N + v] = true
		adjacent[v * MAX_N + u] = true
	}

	query_u, query_v: [MAX_Q]int
	for id := 0; id < q; id += 1 {
		u_value, v_value := input[offset], input[offset + 1]
		offset += 2
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value do return -1
		query_u[id], query_v[id] = int(u_value), int(v_value)
	}

	color_id, first_color: [MAX_N]int
	color_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		rank := 0
		for rank < color_count && colors[first_color[rank]] != colors[vertex] { rank += 1 }
		if rank == color_count { first_color[color_count] = vertex; color_count += 1 }
		color_id[vertex] = rank
	}

	parent, depth, entry, leave: [MAX_N]int
	euler: [2 * MAX_N]int
	event_node, event_parent: [2 * MAX_N]int
	event_exit: [2 * MAX_N]bool
	top, clock := 1, 0
	event_node[0], event_parent[0], event_exit[0] = 0, n, false
	for top > 0 {
		top -= 1
		u, previous, is_exit := event_node[top], event_parent[top], event_exit[top]
		if is_exit {
			leave[u] = clock
			euler[clock] = u
			clock += 1
		} else {
			parent[u] = previous
			entry[u] = clock
			euler[clock] = u
			clock += 1
			event_node[top], event_parent[top], event_exit[top] = u, previous, true
			top += 1
			for v := n - 1; v >= 0; v -= 1 {
				if adjacent[u * MAX_N + v] && v != previous {
					depth[v] = depth[u] + 1
					event_node[top], event_parent[top], event_exit[top] = v, u, false
					top += 1
				}
			}
		}
	}

	queries: [MAX_Q]Query
	block_size := 1
	for (block_size + 1) * (block_size + 1) <= 2 * n { block_size += 1 }
	for id := 0; id < q; id += 1 {
		u, v := query_u[id], query_v[id]
		if entry[u] > entry[v] { temporary := u; u = v; v = temporary }
		ancestor := lca(u, v, parent[:], depth[:])
		left := entry[u]
		if ancestor != u do left = leave[u]
		right := entry[v]
		block := left / block_size
		right_key := right
		if block % 2 != 0 do right_key = 2 * n - 1 - right
			extra := -1
			if ancestor != u do extra = ancestor
			queries[id] = Query{left, right, id, block, right_key, extra}
	}
	sort_queries(queries[:], q)

	counts, answers: [MAX_N]int
	active: [MAX_N]bool
	distinct := 0
	left, right := 0, -1
	for sorted_id := 0; sorted_id < q; sorted_id += 1 {
		query := queries[sorted_id]
		for left > query.left { left -= 1; toggle(euler[left], color_id[:], counts[:], active[:], &distinct) }
		for right < query.right { right += 1; toggle(euler[right], color_id[:], counts[:], active[:], &distinct) }
		for left < query.left { toggle(euler[left], color_id[:], counts[:], active[:], &distinct); left += 1 }
		for right > query.right { toggle(euler[right], color_id[:], counts[:], active[:], &distinct); right -= 1 }
		if query.extra >= 0 {
			toggle(query.extra, color_id[:], counts[:], active[:], &distinct)
			answers[query.id] = distinct
			toggle(query.extra, color_id[:], counts[:], active[:], &distinct)
		} else { answers[query.id] = distinct }
	}

	required := 8 * q
	if output == nil || capacity < c.size_t(required) do return -2
	for id := 0; id < q; id += 1 { store_le(output, 8 * id, i64(answers[id])) }
	return i64(required)
}
