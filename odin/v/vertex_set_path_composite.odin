package vertex_set_path_composite

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MODULUS :: i64(998244353)
MAX_INPUT_VALUES :: 4 * MAX_N + 4 * MAX_Q

Affine :: struct { a, b: i64 }
Aggregate :: struct { forward, backward: Affine }

identity :: proc "contextless" () -> Affine { return {1, 0} }

compose :: proc "contextless" (after, before: Affine) -> Affine {
	return {(after.a * before.a) % MODULUS,
		(after.a * before.b + after.b) % MODULUS}
}

identity_aggregate :: proc "contextless" () -> Aggregate {
	id := identity()
	return {id, id}
}

combine :: proc "contextless" (left, right: Aggregate) -> Aggregate {
	return {compose(right.forward, left.forward), compose(left.backward, right.backward)}
}

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

update_leaf :: proc "contextless" (tree: [^]Aggregate, base, position: int, value: Affine) {
	node := base + position
	tree[node] = {value, value}
	for node > 1 {
		node /= 2
		tree[node] = combine(tree[node * 2], tree[node * 2 + 1])
	}
}

range_query :: proc "contextless" (tree: [^]Aggregate, base, left_value, right_value: int) -> Aggregate {
	mut prefix, suffix := identity_aggregate(), identity_aggregate()
	mut left, right := left_value + base, right_value + base
	for left < right {
		if (left & 1) != 0 { prefix = combine(prefix, tree[left]); left += 1 }
		if (right & 1) != 0 { right -= 1; suffix = combine(tree[right], suffix) }
		left /= 2
		right /= 2
	}
	return combine(prefix, suffix)
}

path_composition :: proc "contextless" (tree: [^]Aggregate, base: int,
		parent, depth, head, position: [^]int, from_value, to_value: int) -> Affine {
	mut left, right := identity(), identity()
	mut from, to := from_value, to_value
	for head[from] != head[to] {
		if depth[head[from]] >= depth[head[to]] {
			part := range_query(tree, base, position[head[from]], position[from] + 1)
			left = compose(part.backward, left)
			from = parent[head[from]]
		} else {
			part := range_query(tree, base, position[head[to]], position[to] + 1)
			right = compose(right, part.forward)
			to = parent[head[to]]
		}
	}
	if depth[from] >= depth[to] {
		part := range_query(tree, base, position[to], position[from] + 1)
		left = compose(part.backward, left)
	} else {
		part := range_query(tree, base, position[from], position[to] + 1)
		right = compose(right, part.forward)
	}
	return compose(right, left)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
vertex_set_path_composite :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 8 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 1 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if length != c.size_t(4 * n + 4 * q) do return -1

	var values: [MAX_N]Affine
	for vertex := 0; vertex < n; vertex += 1 {
		a, b := input[2 + 2 * vertex], input[3 + 2 * vertex]
		if a < 1 || a >= MODULUS || b < 0 || b >= MODULUS do return -1
		values[vertex] = {a, b}
	}
	var adjacent: [MAX_N][MAX_N]bool
	var dsu_parent, dsu_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { dsu_parent[vertex] = vertex; dsu_size[vertex] = 1 }
	edge_start := 2 + 2 * n
	for edge := 0; edge < n - 1; edge += 1 {
		offset := edge_start + 2 * edge
		lv, rv := input[offset], input[offset + 1]
		if lv < 0 || lv >= nv || rv < 0 || rv >= nv || lv == rv do return -1
		left, right := int(lv), int(rv)
		root_left, root_right := find_root(&dsu_parent[0], left), find_root(&dsu_parent[0], right)
		if root_left == root_right do return -1
		if dsu_size[root_left] < dsu_size[root_right] { root_left, root_right = root_right, root_left }
		dsu_parent[root_right] = root_left
		dsu_size[root_left] += dsu_size[root_right]
		adjacent[left][right], adjacent[right][left] = true, true
	}

	operation_start := edge_start + 2 * (n - 1)
	for query := 0; query < q; query += 1 {
		offset := operation_start + 4 * query
		kind, first := input[offset], input[offset + 1]
		second, third := input[offset + 2], input[offset + 3]
		if kind == 0 {
			if first < 0 || first >= nv || second < 1 || second >= MODULUS || third < 0 || third >= MODULUS do return -1
		} else if kind == 1 {
			if first < 0 || first >= nv || second < 0 || second >= nv || third < 0 || third >= MODULUS do return -1
		} else do return -1
	}

	var parent, depth, subtree, heavy, order, stack: [MAX_N]int
	order_count, top := 1, 1
	parent[0], subtree[0], heavy[0], stack[0], order[0] = 0, 1, MAX_N, 0, 0
	for top > 0 {
		top -= 1
		vertex := stack[top]
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if !adjacent[vertex][neighbor] || neighbor == parent[vertex] do continue
			parent[neighbor] = vertex
			depth[neighbor] = depth[vertex] + 1
			subtree[neighbor], heavy[neighbor] = 1, MAX_N
			order[order_count] = neighbor
			order_count += 1
			stack[top] = neighbor
			top += 1
		}
	}
	for index := order_count; index > 1; index -= 1 {
		vertex := order[index - 1]
		p := parent[vertex]
		subtree[p] += subtree[vertex]
		if heavy[p] == MAX_N || subtree[vertex] > subtree[heavy[p]] ||
			(subtree[vertex] == subtree[heavy[p]] && vertex < heavy[p]) { heavy[p] = vertex }
	}

	var head, position, chain_vertex, chain_head: [MAX_N]int
	chain_count, timer := 1, 0
	chain_vertex[0], chain_head[0] = 0, 0
	for chain_count > 0 {
		chain_count -= 1
		vertex, current_head := chain_vertex[chain_count], chain_head[chain_count]
		for vertex != MAX_N {
			head[vertex], position[vertex] = current_head, timer
			timer += 1
			for child := 0; child < n; child += 1 {
				if adjacent[vertex][child] && parent[child] == vertex && child != heavy[vertex] {
					chain_vertex[chain_count], chain_head[chain_count] = child, child
					chain_count += 1
				}
			}
			vertex = heavy[vertex]
		}
	}

	base := 1
	for base < n { base *= 2 }
	var tree: [2 * MAX_N]Aggregate
	for node := 0; node < 2 * base; node += 1 { tree[node] = identity_aggregate() }
	for vertex := 0; vertex < n; vertex += 1 { update_leaf(&tree[0], base, position[vertex], values[vertex]) }
	var answers: [MAX_Q]i64
	answer_count := 0
	for query := 0; query < q; query += 1 {
		offset := operation_start + 4 * query
		kind := input[offset]
		first := int(input[offset + 1])
		second, third := input[offset + 2], input[offset + 3]
		if kind == 0 {
			values[first] = {second, third}
			update_leaf(&tree[0], base, position[first], values[first])
		} else {
			combined := path_composition(&tree[0], base, &parent[0], &depth[0], &head[0], &position[0], first, int(second))
			answers[answer_count] = (combined.a * third + combined.b) % MODULUS
			answer_count += 1
		}
	}
	required := 8 * answer_count
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < answer_count; index += 1 { store_i64_le(output, 8 * index, answers[index]) }
	return i64(required)
}
