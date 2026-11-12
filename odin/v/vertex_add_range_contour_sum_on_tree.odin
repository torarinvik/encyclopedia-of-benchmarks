package vertex_add_range_contour_sum_on_tree

import "core:c"

MAX_N :: 64
MAX_Q :: 128
MAX_LEVEL :: 8
MAX_INPUT_VALUES :: 3 * MAX_N + 4 * MAX_Q + 1
MAX_ABS_VALUE :: i64(1_000_000)

Context :: struct {
	n: int,
	degree: [MAX_N]int,
	adjacent: [MAX_N][MAX_N]int,
	removed: [MAX_N]bool,
	parent: [MAX_N]int,
	subtree_size: [MAX_N]int,
	ancestor: [MAX_N][MAX_LEVEL]int,
	distance: [MAX_N][MAX_LEVEL]int,
	branch_for: [MAX_N][MAX_LEVEL]int,
	path_length: [MAX_N]int,
	branch_count: int,
	total: [MAX_N][MAX_N + 1]i64,
	branch: [MAX_N][MAX_N + 1]i64,
}

collect_component :: proc "contextless" (ctx: ^Context, start: int, order: ^[MAX_N]int) -> int {
	var stack: [MAX_N]int
	top, count := 1, 0
	ctx.parent[start] = -1
	stack[0] = start
	for top > 0 {
		top -= 1
		u := stack[top]
		order[count] = u
		count += 1
		for i := 0; i < ctx.degree[u]; i += 1 {
			v := ctx.adjacent[u][i]
			if ctx.removed[v] || v == ctx.parent[u] do continue
			ctx.parent[v] = u
			stack[top] = v
			top += 1
		}
	}
	for position := count - 1; position >= 0; position -= 1 {
		u := order[position]
		ctx.subtree_size[u] = 1
		for i := 0; i < ctx.degree[u]; i += 1 {
			v := ctx.adjacent[u][i]
			if !ctx.removed[v] && ctx.parent[v] == u do ctx.subtree_size[u] += ctx.subtree_size[v]
		}
	}
	return count
}

decompose :: proc "contextless" (ctx: ^Context, start, level: int) {
	var order: [MAX_N]int
	count := collect_component(ctx, start, &order)
	center := start
	for index := 0; index < count; index += 1 {
		u := order[index]
		largest := count - ctx.subtree_size[u]
		for i := 0; i < ctx.degree[u]; i += 1 {
			v := ctx.adjacent[u][i]
			if !ctx.removed[v] && ctx.parent[v] == u && ctx.subtree_size[v] > largest {
				largest = ctx.subtree_size[v]
			}
		}
		if 2 * largest <= count { center = u; break }
	}
	ctx.removed[center] = true
	ctx.ancestor[center][level] = center
	ctx.distance[center][level] = 0
	ctx.branch_for[center][level] = -1
	ctx.path_length[center] = level + 1
	for edge := 0; edge < ctx.degree[center]; edge += 1 {
		root := ctx.adjacent[center][edge]
		if ctx.removed[root] do continue
		branch_id := ctx.branch_count
		ctx.branch_count += 1
		var nodes, parents, distances: [MAX_N]int
		top := 1
		nodes[0], parents[0], distances[0] = root, center, 1
		for top > 0 {
			top -= 1
			u, p, d := nodes[top], parents[top], distances[top]
			ctx.ancestor[u][level] = center
			ctx.distance[u][level] = d
			ctx.branch_for[u][level] = branch_id
			ctx.path_length[u] = level + 1
			for i := 0; i < ctx.degree[u]; i += 1 {
				v := ctx.adjacent[u][i]
				if ctx.removed[v] || v == p do continue
				nodes[top], parents[top], distances[top] = v, u, d + 1
				top += 1
			}
		}
		decompose(ctx, root, level + 1)
	}
}

fenwick_add :: proc "contextless" (tree: [^]i64, position: int, delta: i64) {
	index := position + 1
	for index <= MAX_N {
		tree[index] += delta
		index += index & -index
	}
}

fenwick_prefix :: proc "contextless" (tree: [^]i64, count: int) -> i64 {
	total: i64 = 0
	index := count
	for index > 0 {
		total += tree[index]
		index -= index & -index
	}
	return total
}

row_range :: proc "contextless" (tree: [^]i64, left, right: int) -> i64 {
	l := max(0, min(MAX_N, left))
	r := max(0, min(MAX_N, right))
	if r <= l do return 0
	return fenwick_prefix(tree, r) - fenwick_prefix(tree, l)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (byte * 8)) }
}

@(export)
vertex_add_range_contour_sum_on_tree :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	nv, qv := input[0], input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n, q := int(nv), int(qv)
	if length < c.size_t(3 * n) do return -1

	var ctx: Context
	ctx.n = n
	for v := 0; v < n; v += 1 {
		for d := 0; d < MAX_LEVEL; d += 1 { ctx.ancestor[v][d], ctx.branch_for[v][d] = -1, -1 }
	}
	var values: [MAX_N]i64
	for v := 0; v < n; v += 1 {
		values[v] = input[2 + v]
		if values[v] < -MAX_ABS_VALUE || values[v] > MAX_ABS_VALUE do return -1
	}
	edge_start := 2 + n
	for i := 0; i < n - 1; i += 1 {
		uv, vv := input[edge_start + 2 * i], input[edge_start + 2 * i + 1]
		if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv do return -1
		u, v := int(uv), int(vv)
		for j := 0; j < ctx.degree[u]; j += 1 { if ctx.adjacent[u][j] == v do return -1 }
		ctx.adjacent[u][ctx.degree[u]] = v
		ctx.degree[u] += 1
		ctx.adjacent[v][ctx.degree[v]] = u
		ctx.degree[v] += 1
	}
	var seen: [MAX_N]bool
	var stack: [MAX_N]int
	top, visited := 1, 0
	stack[0], seen[0] = 0, true
	for top > 0 {
		top -= 1
		u := stack[top]
		visited += 1
		for i := 0; i < ctx.degree[u]; i += 1 {
			v := ctx.adjacent[u][i]
			if !seen[v] { seen[v] = true; stack[top] = v; top += 1 }
		}
	}
	if visited != n do return -1

	var kinds: [MAX_Q]int
	var vertices: [MAX_Q]int
	var first, second: [MAX_Q]i64
	query_count := 0
	cursor := 3 * n
	for i := 0; i < q; i += 1 {
		if cursor >= int(length) do return -1
		op := input[cursor]
		cursor += 1
		if op == 0 {
			if cursor + 2 > int(length) do return -1
			p, delta := input[cursor], input[cursor + 1]
			cursor += 2
			if p < 0 || p >= nv || delta < -MAX_ABS_VALUE || delta > MAX_ABS_VALUE do return -1
			kinds[i], vertices[i], first[i] = 0, int(p), delta
		} else if op == 1 {
			if cursor + 3 > int(length) do return -1
			p, left, right := input[cursor], input[cursor + 1], input[cursor + 2]
			cursor += 3
			if p < 0 || p >= nv || left < 0 || left >= right || right > nv do return -1
			kinds[i], vertices[i], first[i], second[i] = 1, int(p), left, right
			query_count += 1
		} else do return -1
	}
	if cursor != int(length) do return -1

	decompose(&ctx, 0, 0)
	for v := 0; v < n; v += 1 {
		for d := 0; d < ctx.path_length[v]; d += 1 {
			c := ctx.ancestor[v][d]
			branch_id := ctx.branch_for[v][d]
			fenwick_add(&ctx.total[c][0], ctx.distance[v][d], values[v])
			if branch_id >= 0 do fenwick_add(&ctx.branch[branch_id][0], ctx.distance[v][d], values[v])
		}
	}
	var answers: [MAX_Q]i64
	answer_count := 0
	for i := 0; i < q; i += 1 {
		p := vertices[i]
		if kinds[i] == 0 {
			for d := 0; d < ctx.path_length[p]; d += 1 {
				c := ctx.ancestor[p][d]
				branch_id := ctx.branch_for[p][d]
				fenwick_add(&ctx.total[c][0], ctx.distance[p][d], first[i])
				if branch_id >= 0 do fenwick_add(&ctx.branch[branch_id][0], ctx.distance[p][d], first[i])
			}
		} else {
			total: i64 = 0
			left, right := int(first[i]), int(second[i])
			for d := 0; d < ctx.path_length[p]; d += 1 {
				c := ctx.ancestor[p][d]
				branch_id := ctx.branch_for[p][d]
				l, r := left - ctx.distance[p][d], right - ctx.distance[p][d]
				total += row_range(&ctx.total[c][0], l, r)
				if branch_id >= 0 do total -= row_range(&ctx.branch[branch_id][0], l, r)
			}
			answers[answer_count] = total
			answer_count += 1
		}
	}
	output_bytes := 8 * answer_count
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
	for i := 0; i < answer_count; i += 1 { store_i64_le(output, 8 * i, answers[i]) }
	return i64(output_bytes)
}
