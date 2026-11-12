module vertex_add_range_contour_sum_on_tree

import math

const max_n = 64
const max_q = 128
const max_level = 8
const max_input_values = usize(3 * max_n + 4 * max_q + 1)
const max_abs_value = i64(1_000_000)
const row_size = max_n + 1

struct WalkItem {
	node int
	parent int
	distance int
}

struct Context {
	n int
	degree []int
	adjacent []int
	removed []bool
	parent []int
	subtree_size []int
	ancestor []int
	distance []int
	branch_for []int
	path_length []int
	branch_count int
	total []i64
	branch []i64
}

fn new_context(n int) Context {
	return Context{
		n: n
		degree: []int{len: max_n}
		adjacent: []int{len: max_n * max_n}
		removed: []bool{len: max_n}
		parent: []int{len: max_n, init: -1}
		subtree_size: []int{len: max_n}
		ancestor: []int{len: max_n * max_level, init: -1}
		distance: []int{len: max_n * max_level}
		branch_for: []int{len: max_n * max_level, init: -1}
		path_length: []int{len: max_n}
		total: []i64{len: max_n * row_size}
		branch: []i64{len: max_n * row_size}
	}
}

fn collect_component(mut ctx Context, start int, mut order []int) int {
	mut stack := []int{len: max_n}
	mut top := 1
	mut count := 0
	ctx.parent[start] = -1
	stack[0] = start
	for top > 0 {
		top--
		u := stack[top]
		order[count] = u
		count++
		for i in 0 .. ctx.degree[u] {
			v := ctx.adjacent[u * max_n + i]
			if ctx.removed[v] || v == ctx.parent[u] { continue }
			ctx.parent[v] = u
			stack[top] = v
			top++
		}
	}
	for position := count - 1; position >= 0; position-- {
		u := order[position]
		ctx.subtree_size[u] = 1
		for i in 0 .. ctx.degree[u] {
			v := ctx.adjacent[u * max_n + i]
			if !ctx.removed[v] && ctx.parent[v] == u { ctx.subtree_size[u] += ctx.subtree_size[v] }
		}
	}
	return count
}

fn decompose(mut ctx Context, start int, level int) {
	mut order := []int{len: max_n}
	count := collect_component(mut ctx, start, mut order)
	mut center := start
	for index in 0 .. count {
		u := order[index]
		mut largest := count - ctx.subtree_size[u]
		for i in 0 .. ctx.degree[u] {
			v := ctx.adjacent[u * max_n + i]
			if !ctx.removed[v] && ctx.parent[v] == u && ctx.subtree_size[v] > largest {
				largest = ctx.subtree_size[v]
			}
		}
		if 2 * largest <= count { center = u; break }
	}
	ctx.removed[center] = true
	ctx.ancestor[center * max_level + level] = center
	ctx.distance[center * max_level + level] = 0
	ctx.branch_for[center * max_level + level] = -1
	ctx.path_length[center] = level + 1
	for edge in 0 .. ctx.degree[center] {
		root := ctx.adjacent[center * max_n + edge]
		if ctx.removed[root] { continue }
		branch_id := ctx.branch_count
		ctx.branch_count++
		mut walk := []WalkItem{len: max_n}
		mut top := 1
		walk[0] = WalkItem{node: root, parent: center, distance: 1}
		for top > 0 {
			top--
			item := walk[top]
			idx := item.node * max_level + level
			ctx.ancestor[idx] = center
			ctx.distance[idx] = item.distance
			ctx.branch_for[idx] = branch_id
			ctx.path_length[item.node] = level + 1
			for i in 0 .. ctx.degree[item.node] {
				v := ctx.adjacent[item.node * max_n + i]
				if ctx.removed[v] || v == item.parent { continue }
				walk[top] = WalkItem{node: v, parent: item.node, distance: item.distance + 1}
				top++
			}
		}
		decompose(mut ctx, root, level + 1)
	}
}

fn fenwick_add(mut tree []i64, row int, position int, delta i64) {
	mut index := position + 1
	for index <= max_n {
		tree[row * row_size + index] += delta
		index += index & -index
	}
}

fn fenwick_prefix(tree []i64, row int, count int) i64 {
	mut total := i64(0)
	mut index := count
	for index > 0 {
		total += tree[row * row_size + index]
		index -= index & -index
	}
	return total
}

fn row_range(tree []i64, row int, left int, right int) i64 {
	l := math.max(0, math.min(max_n, left))
	r := math.max(0, math.min(max_n, right))
	if r <= l { return 0 }
	return fenwick_prefix(tree, row, r) - fenwick_prefix(tree, row, l)
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		mut bits := u64(value)
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'vertex_add_range_contour_sum_on_tree']
pub fn vertex_add_range_contour_sum_on_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	unsafe {
		nv, qv := input[0], input[1]
		if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
		n, q := int(nv), int(qv)
		if length < usize(3 * n) { return -1 }
		mut ctx := new_context(n)
		mut values := []i64{len: max_n}
		for v in 0 .. n {
			values[v] = input[2 + v]
			if values[v] < -max_abs_value || values[v] > max_abs_value { return -1 }
		}
		edge_start := 2 + n
		for i in 0 .. n - 1 {
			uv, vv := input[edge_start + 2 * i], input[edge_start + 2 * i + 1]
			if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv { return -1 }
			u, v := int(uv), int(vv)
			for j in 0 .. ctx.degree[u] {
				if ctx.adjacent[u * max_n + j] == v { return -1 }
			}
			ctx.adjacent[u * max_n + ctx.degree[u]] = v
			ctx.degree[u]++
			ctx.adjacent[v * max_n + ctx.degree[v]] = u
			ctx.degree[v]++
		}
		mut seen := []bool{len: max_n}
		mut stack := []int{len: max_n}
		mut top, visited := 1, 0
		stack[0], seen[0] = 0, true
		for top > 0 {
			top--
			u := stack[top]
			visited++
			for i in 0 .. ctx.degree[u] {
				v := ctx.adjacent[u * max_n + i]
				if !seen[v] { seen[v] = true; stack[top] = v; top++ }
			}
		}
		if visited != n { return -1 }

		mut kinds := []int{len: max_q}
		mut vertices := []int{len: max_q}
		mut first, second := []i64{len: max_q}, []i64{len: max_q}
		mut query_count := 0
		mut cursor := 3 * n
		for i in 0 .. q {
			if cursor >= int(length) { return -1 }
			op := input[cursor]
			cursor++
			if op == 0 {
				if cursor + 2 > int(length) { return -1 }
				p, delta := input[cursor], input[cursor + 1]
				cursor += 2
				if p < 0 || p >= nv || delta < -max_abs_value || delta > max_abs_value { return -1 }
				kinds[i], vertices[i], first[i] = 0, int(p), delta
			} else if op == 1 {
				if cursor + 3 > int(length) { return -1 }
				p, left, right := input[cursor], input[cursor + 1], input[cursor + 2]
				cursor += 3
				if p < 0 || p >= nv || left < 0 || left >= right || right > nv { return -1 }
				kinds[i], vertices[i], first[i], second[i] = 1, int(p), left, right
				query_count++
			} else { return -1 }
		}
		if cursor != int(length) { return -1 }

		decompose(mut ctx, 0, 0)
		for v in 0 .. n {
			for d in 0 .. ctx.path_length[v] {
				c := ctx.ancestor[v * max_level + d]
				branch_id := ctx.branch_for[v * max_level + d]
				fenwick_add(mut ctx.total, c, ctx.distance[v * max_level + d], values[v])
				if branch_id >= 0 { fenwick_add(mut ctx.branch, branch_id, ctx.distance[v * max_level + d], values[v]) }
			}
		}
		mut answers := []i64{len: max_q}
		mut answer_count := 0
		for i in 0 .. q {
			p := vertices[i]
			if kinds[i] == 0 {
				for d in 0 .. ctx.path_length[p] {
					c := ctx.ancestor[p * max_level + d]
					branch_id := ctx.branch_for[p * max_level + d]
					fenwick_add(mut ctx.total, c, ctx.distance[p * max_level + d], first[i])
					if branch_id >= 0 { fenwick_add(mut ctx.branch, branch_id, ctx.distance[p * max_level + d], first[i]) }
				}
			} else {
				mut total := i64(0)
				left, right := int(first[i]), int(second[i])
				for d in 0 .. ctx.path_length[p] {
					c := ctx.ancestor[p * max_level + d]
					branch_id := ctx.branch_for[p * max_level + d]
					l, r := left - ctx.distance[p * max_level + d], right - ctx.distance[p * max_level + d]
					total += row_range(ctx.total, c, l, r)
					if branch_id >= 0 { total -= row_range(ctx.branch, branch_id, l, r) }
				}
				answers[answer_count] = total
				answer_count++
			}
		}
		output_bytes := 8 * answer_count
		if output_bytes > 0 && (unsafe { output == nil } || capacity < usize(output_bytes)) { return -2 }
		for i in 0 .. answer_count { store_i64_le(mut output, 8 * i, answers[i]) }
		return i64(output_bytes)
	}
}
