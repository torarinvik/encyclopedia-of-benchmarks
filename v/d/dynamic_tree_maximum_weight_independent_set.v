module dynamic_tree_maximum_weight_independent_set

const max_n = 64
const max_q = 64
const max_input = 320
const max_weight = i64(1000000)
const neg = i64(-1152921504606846976)

struct Matrix {
mut:
	a [2][2]i64
}

fn identity() Matrix {
	mut m := Matrix{}
	m.a[0][0] = 0; m.a[0][1] = neg
	m.a[1][0] = neg; m.a[1][1] = 0
	return m
}

fn maximum(a i64, b i64) i64 { return if a > b { a } else { b } }

fn multiply(a Matrix, b Matrix) Matrix {
	mut result := Matrix{}
	for row in 0 .. 2 {
		for col in 0 .. 2 {
			result.a[row][col] = maximum(a.a[row][0] + b.a[0][col], a.a[row][1] + b.a[1][col])
		}
	}
	return result
}

fn find_root(mut parent []int, vertex int) int {
	mut v := vertex
	for parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v] }
	return v
}

fn set_matrix(mut tree []Matrix, position int, value Matrix) {
	mut node := max_n + position
	tree[node] = value
	node /= 2
	for node > 0 { tree[node] = multiply(tree[2*node], tree[2*node+1]); node /= 2 }
}

fn query(tree []Matrix, left int, right int) Matrix {
	mut l := max_n + left
	mut r := max_n + right
	mut before := identity()
	mut after := identity()
	for l < r {
		if l % 2 == 1 { before = multiply(before, tree[l]); l++ }
		if r % 2 == 1 { r--; after = multiply(tree[r], after) }
		l /= 2; r /= 2
	}
	return multiply(before, after)
}

fn summary(tree []Matrix, position []int, tail []int, h int) [2]i64 {
	p := query(tree, position[h], position[tail[h]] + 1)
	return [2]i64{maximum(p.a[0][0], p.a[0][1]), maximum(p.a[1][0], p.a[1][1])}
}

fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte] = u8(bits >> (8*byte)) } }
}

@[export: 'dynamic_tree_maximum_weight_independent_set']
pub fn dynamic_tree_maximum_weight_independent_set(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input) { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 1 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv); q := int(qv); edge_end := 2 + n + 2*(n-1)
	if length != usize(edge_end + 2*q) { return -1 }
	mut dsu := [max_n]int{}; mut weights := [max_n]i64{}; mut adjacency := [max_n*max_n]bool{}
	for u in 0 .. n {
		dsu[u] = u; weights[u] = unsafe { input[2+u] }
		if weights[u] < 0 || weights[u] > max_weight { return -1 }
	}
	for edge in 0 .. n-1 {
		off := 2+n+2*edge; uu := unsafe { input[off] }; vv := unsafe { input[off+1] }
		if uu < 0 || uu >= nv || vv < 0 || vv >= nv || uu == vv { return -1 }
		u := int(uu); v := int(vv); ru := find_root(mut dsu[..],u); rv := find_root(mut dsu[..],v)
		if ru == rv { return -1 }
		dsu[ru] = rv; adjacency[u*max_n+v] = true; adjacency[v*max_n+u] = true
	}
	root_set := find_root(mut dsu[..],0)
	for v in 1 .. n { if find_root(mut dsu[..],v) != root_set { return -1 } }
	mut update_vertex := [max_q]int{}; mut update_weight := [max_q]i64{}
	for i in 0 .. q {
		off := edge_end+2*i; vertex := unsafe { input[off] }; weight := unsafe { input[off+1] }
		if vertex < 0 || vertex >= nv || weight < 0 || weight > max_weight { return -1 }
		update_vertex[i] = int(vertex); update_weight[i] = weight
	}
	output_bytes := 8*q
	if output_bytes > 0 && (unsafe { output == nil } || capacity < usize(output_bytes)) { return -2 }

	mut parent := [max_n]int{}; mut order := [max_n]int{}
	for v in 0 .. n { parent[v] = -2 }
	parent[0] = -1; order[0] = 0; mut order_count := 1; mut cursor := 0
	for cursor < order_count {
		u := order[cursor]; cursor++
		for v in 0 .. n {
			if adjacency[u*max_n+v] && parent[v] == -2 { parent[v] = u; order[order_count] = v; order_count++ }
		}
	}
	mut subtree := [max_n]int{}; mut heavy := [max_n]int{}
	mut skip := [max_n]i64{}; mut take := [max_n]i64{}
	for u in 0 .. n { subtree[u] = 1; heavy[u] = -1; take[u] = weights[u] }
	mut index := n-1
	for index > 0 {
		index--; u := order[index]; p := parent[u]; subtree[p] += subtree[u]
		if heavy[p] < 0 || subtree[u] > subtree[heavy[p]] { heavy[p] = u }
		skip[p] += maximum(skip[u],take[u]); take[p] += skip[u]
	}
	mut head := [max_n]int{}; mut position := [max_n]int{}; mut tail := [max_n]int{}
	mut stack := [max_n]int{}; stack[0] = 0; mut stack_len := 1; mut clock := 0
	for stack_len > 0 {
		stack_len--; h := stack[stack_len]; mut u := h
		for u >= 0 {
			head[u] = h; position[u] = clock; clock++; tail[h] = u
			for v in 1 .. n { if parent[v] == u && v != heavy[u] { stack[stack_len] = v; stack_len++ } }
			u = heavy[u]
		}
	}
	mut matrices := [max_n]Matrix{}; mut segment := [2*max_n]Matrix{}
	for i in 0 .. 2*max_n { segment[i] = identity() }
	for u in 0 .. n {
		mut light0 := i64(0); mut light1 := weights[u]
		for v in 1 .. n { if parent[v] == u && v != heavy[u] { light0 += maximum(skip[v],take[v]); light1 += skip[v] } }
		matrices[u].a[0][0] = light0; matrices[u].a[0][1] = light0
		matrices[u].a[1][0] = light1; matrices[u].a[1][1] = neg
		segment[max_n+position[u]] = matrices[u]
	}
	mut build := max_n-1
	for build > 0 { segment[build] = multiply(segment[2*build],segment[2*build+1]); build-- }
	mut staged := [max_q]i64{}
	for i in 0 .. q {
		vertex := update_vertex[i]; mut h := head[vertex]; mut old_state := summary(segment[..],position[..],tail[..],h)
		delta := update_weight[i]-weights[vertex]; weights[vertex] = update_weight[i]
		matrices[vertex].a[1][0] += delta; set_matrix(mut segment[..],position[vertex],matrices[vertex])
		mut new_state := summary(segment[..],position[..],tail[..],h)
		for parent[h] != -1 {
			p := parent[h]; ph := head[p]; before := summary(segment[..],position[..],tail[..],ph)
			delta0 := maximum(new_state[0],new_state[1])-maximum(old_state[0],old_state[1])
			delta1 := new_state[0]-old_state[0]
			matrices[p].a[0][0] += delta0; matrices[p].a[0][1] += delta0; matrices[p].a[1][0] += delta1
			set_matrix(mut segment[..],position[p],matrices[p]); old_state = before
			new_state = summary(segment[..],position[..],tail[..],ph); h = ph
		}
		answer := summary(segment[..],position[..],tail[..],0); staged[i] = maximum(answer[0],answer[1])
	}
	for i in 0 .. q { store_le(mut output,8*i,staged[i]) }
	return i64(output_bytes)
}
