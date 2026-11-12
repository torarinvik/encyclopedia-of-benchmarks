const max_n = 16
const max_q = 32
const max_edges = 15
const log_n = 5

fn root_of(mut parent []int, node_arg int) int {
	mut node := node_arg
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn point_set(mut tree []i64, base int, index int, value i64) {
	mut position := base + index
	tree[position] = value
	position /= 2
	for position > 0 {
		tree[position] = tree[2 * position] + tree[2 * position + 1]
		position /= 2
	}
}

fn range_sum(tree []i64, base int, left int, right int) i64 {
	if left > right { return 0 }
	mut l := base + left
	mut r := base + right + 1
	mut total := i64(0)
	for l < r {
		if (l & 1) == 1 { total += tree[l]; l++ }
		if (r & 1) == 1 { r--; total += tree[r] }
		l /= 2
		r /= 2
	}
	return total
}

fn lca(a_arg int, b_arg int, depth []int, parent []int, ancestor []int) int {
	mut a := a_arg
	mut b := b_arg
	if depth[a] < depth[b] { a, b = b, a }
	mut difference := depth[a] - depth[b]
	for bit in 0 .. log_n {
		if ((difference >> bit) & 1) != 0 { a = ancestor[bit * max_n + a] }
	}
	if a == b { return a }
	for bit := log_n - 1; bit >= 0; bit-- {
		if ancestor[bit * max_n + a] != ancestor[bit * max_n + b] {
			a = ancestor[bit * max_n + a]
			b = ancestor[bit * max_n + b]
		}
	}
	return parent[a]
}

@[export: 'tree_edge_paint_path_count']
pub fn tree_edge_paint_path_count(input &i64, length usize) i64 {
	if length < 2 || length > 129 { return -1 }
	unsafe {
		if input == nil { return -1 }
		if input[0] < 1 || input[0] > i64(max_n) || input[1] < 0 || input[1] > i64(max_q) { return -1 }
		n, q := int(input[0]), int(input[1])
		m := n - 1
		if length != usize(2 + 2 * m + 3 * q) { return -1 }
		mut edge_u := []int{len: max_edges}
		mut edge_v := []int{len: max_edges}
		mut dsu := []int{len: max_n}
		for i in 0 .. n { dsu[i] = i }
		mut cursor := 2
		for edge in 0 .. m {
			u_value, v_value := input[cursor], input[cursor + 1]
			cursor += 2
			if u_value < 0 || u_value >= i64(n) || v_value < 0 || v_value >= i64(n) || u_value == v_value { return -1 }
			u, v := int(u_value), int(v_value)
			edge_u[edge], edge_v[edge] = u, v
			ru, rv := root_of(mut dsu, u), root_of(mut dsu, v)
			if ru == rv { return -1 }
			dsu[ru] = rv
		}
		root := root_of(mut dsu, 0)
		for v in 1 .. n { if root_of(mut dsu, v) != root { return -1 } }

		mut parent := []int{len: max_n}
		mut depth := []int{len: max_n}
		mut first := []int{len: max_n}
		mut visited := []bool{len: max_n}
		mut down := []int{len: max_edges}
		mut up := []int{len: max_edges}
		mut stack_node := []int{len: max_n}
		mut stack_parent := []int{len: max_n, init: -1}
		mut stack_in := []int{len: max_n, init: -1}
		mut stack_cursor := []int{len: max_n}
		visited[0] = true
		mut top := 0
		mut occurrences := 0
		for top >= 0 {
			node := stack_node[top]
			mut found := false
			for stack_cursor[top] < m {
				edge := stack_cursor[top]
				stack_cursor[top]++
				if edge_u[edge] != node && edge_v[edge] != node { continue }
				child := edge_u[edge]
				if child == node { child = edge_v[edge] }
				if child == stack_parent[top] { continue }
				if visited[child] { return -1 }
				visited[child] = true
				parent[child] = node
				depth[child] = depth[node] + 1
				down[edge] = occurrences
				occurrences++
				first[child] = occurrences
				top++
				stack_node[top], stack_parent[top], stack_in[top], stack_cursor[top] = child, node, edge, 0
				found = true
				break
			}
			if !found {
				incoming := stack_in[top]
				top--
				if incoming >= 0 { up[incoming] = occurrences; occurrences++ }
			}
		}
		mut ancestor := []int{len: log_n * max_n}
		for v in 0 .. n { ancestor[v] = parent[v] }
		for k in 1 .. log_n {
			for v in 0 .. n { ancestor[k * max_n + v] = ancestor[(k - 1) * max_n + ancestor[(k - 1) * max_n + v]] }
		}
		mut base := 1
		for base < occurrences { base *= 2 }
		mut forward := []i64{len: 64}
		mut backward := []i64{len: 64}
		mut painted := []bool{len: max_edges}
		mut total := i64(0)
		for _ in 0 .. q {
			kind, a, b := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if kind == 0 {
				if a < 0 || a >= m || b != 0 { return -1 }
				edge := int(a)
				if !painted[edge] {
					painted[edge] = true
					point_set(mut forward, base, down[edge], 1)
					point_set(mut backward, base, up[edge], 1)
				}
			} else if kind == 1 {
				if a < 0 || a >= n || b < 0 || b >= n { return -1 }
				common := lca(int(a), int(b), depth, parent, ancestor)
				left_a, right_a := first[common], first[int(a)] - 1
				left_b, right_b := first[common], first[int(b)] - 1
				total += range_sum(forward, base, left_a, right_a) - range_sum(backward, base, left_a, right_a)
				total += range_sum(forward, base, left_b, right_b) - range_sum(backward, base, left_b, right_b)
			} else { return -1 }
		}
		return total
	}
}
