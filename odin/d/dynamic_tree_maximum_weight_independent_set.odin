package dynamic_tree_maximum_weight_independent_set

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT :: 320
MAX_WEIGHT :: 1_000_000
NEG :: i64 = -1_152_921_504_606_846_976
Matrix :: [2][2]i64

identity :: proc "contextless" () -> Matrix {
	result: Matrix
	result[0][0] = 0; result[0][1] = NEG
	result[1][0] = NEG; result[1][1] = 0
	return result
}

max_i64 :: proc "contextless" (a, b: i64) -> i64 { if a > b do return a; return b }

multiply :: proc "contextless" (a, b: Matrix) -> Matrix {
	result: Matrix
	for row := 0; row < 2; row += 1 {
		for col := 0; col < 2; col += 1 {
			result[row][col] = max_i64(a[row][0]+b[0][col], a[row][1]+b[1][col])
		}
	}
	return result
}

find_root :: proc "contextless" (parent: [^]int, vertex: int) -> int {
	v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}

set_matrix :: proc "contextless" (tree: [^]Matrix, position: int, value: Matrix) {
	node := MAX_N + position
	tree[node] = value
	node /= 2
	for node > 0 { tree[node] = multiply(tree[2*node], tree[2*node+1]); node /= 2 }
}

query :: proc "contextless" (tree: [^]Matrix, left, right: int) -> Matrix {
	l := MAX_N+left; r := MAX_N+right
	before := identity(); after := identity()
	for l < r {
		if l%2 == 1 { before = multiply(before,tree[l]); l += 1 }
		if r%2 == 1 { r -= 1; after = multiply(tree[r],after) }
		l /= 2; r /= 2
	}
	return multiply(before,after)
}

summary :: proc "contextless" (tree: [^]Matrix, position, tail: [^]int, head: int, result: [^]i64) {
	p := query(tree,position[head],position[tail[head]]+1)
	result[0] = max_i64(p[0][0],p[0][1]); result[1] = max_i64(p[1][0],p[1][1])
}

store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
dynamic_tree_maximum_weight_independent_set :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	nv := input[0]; qv := input[1]
	if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
	n := int(nv); q := int(qv); edge_end := 2+n+2*(n-1)
	if length != c.size_t(edge_end+2*q) do return -1
	dsu: [MAX_N]int; weights: [MAX_N]i64; adjacency: [MAX_N*MAX_N]bool
	for u := 0; u < n; u += 1 {
		dsu[u] = u; weights[u] = input[2+u]
		if weights[u] < 0 || weights[u] > MAX_WEIGHT do return -1
	}
	for edge := 0; edge < n-1; edge += 1 {
		off := 2+n+2*edge; uu := input[off]; vv := input[off+1]
		if uu < 0 || uu >= nv || vv < 0 || vv >= nv || uu == vv do return -1
		u := int(uu); v := int(vv); ru := find_root(&dsu[0],u); rv := find_root(&dsu[0],v)
		if ru == rv do return -1
		dsu[ru] = rv; adjacency[u*MAX_N+v] = true; adjacency[v*MAX_N+u] = true
	}
	tree_root := find_root(&dsu[0],0)
	for v := 1; v < n; v += 1 { if find_root(&dsu[0],v) != tree_root do return -1 }
	update_vertex: [MAX_Q]int; update_weight: [MAX_Q]i64
	for i := 0; i < q; i += 1 {
		off := edge_end+2*i; vertex := input[off]; weight := input[off+1]
		if vertex < 0 || vertex >= nv || weight < 0 || weight > MAX_WEIGHT do return -1
		update_vertex[i] = int(vertex); update_weight[i] = weight
	}
	output_bytes := 8*q
	if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2

	parent: [MAX_N]int; order: [MAX_N]int
	for v := 0; v < n; v += 1 { parent[v] = -2 }
	parent[0] = -1; order[0] = 0; order_count := 1; cursor := 0
	for cursor < order_count {
		u := order[cursor]; cursor += 1
		for v := 0; v < n; v += 1 {
			if adjacency[u*MAX_N+v] && parent[v] == -2 { parent[v] = u; order[order_count] = v; order_count += 1 }
		}
	}
	subtree: [MAX_N]int; heavy: [MAX_N]int; skip: [MAX_N]i64; take: [MAX_N]i64
	for u := 0; u < n; u += 1 { subtree[u] = 1; heavy[u] = -1; take[u] = weights[u] }
	for index := n-1; index > 0; index -= 1 {
		u := order[index]; p := parent[u]; subtree[p] += subtree[u]
		if heavy[p] < 0 || subtree[u] > subtree[heavy[p]] { heavy[p] = u }
		skip[p] += max_i64(skip[u],take[u]); take[p] += skip[u]
	}
	head: [MAX_N]int; position: [MAX_N]int; tail: [MAX_N]int
	stack: [MAX_N]int; stack[0] = 0; stack_len := 1; clock := 0
	for stack_len > 0 {
		stack_len -= 1; h := stack[stack_len]; u := h
		for u >= 0 {
			head[u] = h; position[u] = clock; clock += 1; tail[h] = u
			for v := 1; v < n; v += 1 {
				if parent[v] == u && v != heavy[u] { stack[stack_len] = v; stack_len += 1 }
			}
			u = heavy[u]
		}
	}
	matrices: [MAX_N]Matrix; segment: [2*MAX_N]Matrix
	for i := 0; i < 2*MAX_N; i += 1 { segment[i] = identity() }
	for u := 0; u < n; u += 1 {
		light0: i64 = 0; light1 := weights[u]
		for v := 1; v < n; v += 1 {
			if parent[v] == u && v != heavy[u] { light0 += max_i64(skip[v],take[v]); light1 += skip[v] }
		}
		matrices[u][0][0] = light0; matrices[u][0][1] = light0
		matrices[u][1][0] = light1; matrices[u][1][1] = NEG
		segment[MAX_N+position[u]] = matrices[u]
	}
	for i := MAX_N-1; i > 0; i -= 1 { segment[i] = multiply(segment[2*i],segment[2*i+1]) }
	staged: [MAX_Q]i64
	for i := 0; i < q; i += 1 {
		vertex := update_vertex[i]; h := head[vertex]; old_state: [2]i64; new_state: [2]i64
		summary(&segment[0],&position[0],&tail[0],h,&old_state[0])
		delta := update_weight[i]-weights[vertex]; weights[vertex] = update_weight[i]
		matrices[vertex][1][0] += delta; set_matrix(&segment[0],position[vertex],matrices[vertex])
		summary(&segment[0],&position[0],&tail[0],h,&new_state[0])
		for parent[h] != -1 {
			p := parent[h]; ph := head[p]; before: [2]i64
			summary(&segment[0],&position[0],&tail[0],ph,&before[0])
			delta0 := max_i64(new_state[0],new_state[1])-max_i64(old_state[0],old_state[1])
			delta1 := new_state[0]-old_state[0]
			matrices[p][0][0] += delta0; matrices[p][0][1] += delta0; matrices[p][1][0] += delta1
			set_matrix(&segment[0],position[p],matrices[p])
			old_state = before
			summary(&segment[0],&position[0],&tail[0],ph,&new_state[0]); h = ph
		}
		answer: [2]i64; summary(&segment[0],&position[0],&tail[0],0,&answer[0])
		staged[i] = max_i64(answer[0],answer[1])
	}
	for i := 0; i < q; i += 1 { store_le(output,8*i,staged[i]) }
	return i64(output_bytes)
}
