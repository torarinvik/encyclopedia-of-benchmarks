package euler_tour_tree

import "core:c"

N :: 8
M :: 32
NODES :: N + 2*M
INPUT_MAX :: 2 + N + 3*M

Ett_Op :: struct { kind, a, b: i64 }
Ett_Tree :: struct {
	left, right, parent, vertex, size, count: [NODES]int,
	value, total: [NODES]i64,
	priority: [NODES]i64,
	edge_u, edge_v, arc_uv, arc_vu: [M]int,
	active: [M]bool,
	next_node, edge_count: int,
}

ett_size :: proc(t: ^Ett_Tree, node: int) -> int { if node < 0 { return 0 }; return t.size[node] }
ett_count :: proc(t: ^Ett_Tree, node: int) -> int { if node < 0 { return 0 }; return t.count[node] }
ett_total :: proc(t: ^Ett_Tree, node: int) -> i64 { if node < 0 { return 0 }; return t.total[node] }
ett_pull :: proc(t: ^Ett_Tree, node: int) {
	if node < 0 { return }
	t.size[node] = 1 + ett_size(t,t.left[node]) + ett_size(t,t.right[node])
	own := 0; if t.vertex[node] >= 0 { own = 1 }
	t.count[node] = own + ett_count(t,t.left[node]) + ett_count(t,t.right[node])
	t.total[node] = t.value[node] + ett_total(t,t.left[node]) + ett_total(t,t.right[node])
}
ett_merge :: proc(t: ^Ett_Tree, a, b: int) -> int {
	if a < 0 { if b >= 0 { t.parent[b] = -1 }; return b }
	if b < 0 { t.parent[a] = -1; return a }
	if t.priority[a] > t.priority[b] {
		child := ett_merge(t,t.right[a],b); t.right[a] = child
		if child >= 0 { t.parent[child] = a }; ett_pull(t,a); t.parent[a] = -1; return a
	}
	child := ett_merge(t,a,t.left[b]); t.left[b] = child
	if child >= 0 { t.parent[child] = b }; ett_pull(t,b); t.parent[b] = -1; return b
}
ett_split :: proc(t: ^Ett_Tree, root, prefix: int, first, rest: ^int) {
	if root < 0 { first^ = -1; rest^ = -1; return }
	if prefix <= ett_size(t,t.left[root]) {
		ett_split(t,t.left[root],prefix,first,rest); t.left[root] = rest^
		if rest^ >= 0 { t.parent[rest^] = root }; ett_pull(t,root); t.parent[root] = -1
		if first^ >= 0 { t.parent[first^] = -1 }; rest^ = root; return
	}
	ett_split(t,t.right[root],prefix-ett_size(t,t.left[root])-1,first,rest); t.right[root] = first^
	if first^ >= 0 { t.parent[first^] = root }; ett_pull(t,root); t.parent[root] = -1
	if rest^ >= 0 { t.parent[rest^] = -1 }; first^ = root
}
ett_root :: proc(t: ^Ett_Tree, x0: int) -> int { x := x0; for t.parent[x] >= 0 { x = t.parent[x] }; return x }
ett_position :: proc(t: ^Ett_Tree, x0: int) -> int {
	x := x0; result := ett_size(t,t.left[x])
	for t.parent[x] >= 0 { p := t.parent[x]; if t.right[p] == x { result += 1 + ett_size(t,t.left[p]) }; x = p }
	return result
}
ett_rotate :: proc(t: ^Ett_Tree, root, node: int) -> int {
	first, rest: int; ett_split(t,root,ett_position(t,node),&first,&rest); return ett_merge(t,rest,first)
}
ett_connected :: proc(adj: [^]bool, start, target, n: int) -> bool {
	seen: [N]bool; stack: [N]int; top := 1; stack[0] = start; seen[start] = true
	for top > 0 { top -= 1; u := stack[top]; if u == target { return true }
		for v in 0..<n { if adj[u*N+v] && !seen[v] { seen[v] = true; stack[top] = v; top += 1 } }
	}
	return false
}
ett_initialize :: proc(t: ^Ett_Tree, weights: [N]i64, n: int) {
	for i in 0..<NODES {
		t.left[i] = -1; t.right[i] = -1; t.parent[i] = -1; t.vertex[i] = -1
		t.size[i] = 0; t.count[i] = 0; t.value[i] = 0; t.total[i] = 0
		t.priority[i] = (i*40503+17)%65521
	}
	for i in 0..<M { t.active[i] = false }
	for i in 0..<n { t.vertex[i] = i; t.value[i] = weights[i]; t.total[i] = weights[i]; t.size[i] = 1; t.count[i] = 1 }
	t.next_node = n; t.edge_count = 0
}
ett_link :: proc(t: ^Ett_Tree, u, v: int) {
	a := ett_rotate(t,ett_root(t,u),u); b := ett_rotate(t,ett_root(t,v),v)
	uv := t.next_node; vu := uv+1; t.next_node += 2
	for x in [2]int{uv,vu} { t.left[x] = -1; t.right[x] = -1; t.parent[x] = -1; t.vertex[x] = -1; t.value[x] = 0; t.total[x] = 0; t.size[x] = 1; t.count[x] = 0 }
	root := ett_merge(t,ett_merge(t,ett_merge(t,a,uv),b),vu); t.parent[root] = -1
	e := t.edge_count; t.edge_count += 1; t.edge_u[e] = u; t.edge_v[e] = v; t.arc_uv[e] = uv; t.arc_vu[e] = vu; t.active[e] = true
}
ett_cut :: proc(t: ^Ett_Tree, u, v: int) {
	edge := -1
	for offset := t.edge_count-1; offset >= 0; offset -= 1 {
		if t.active[offset] && ((t.edge_u[offset] == u && t.edge_v[offset] == v) || (t.edge_u[offset] == v && t.edge_v[offset] == u)) { edge = offset; break }
	}
	first_arc := t.arc_vu[edge]; if t.edge_u[edge] == u && t.edge_v[edge] == v { first_arc = t.arc_uv[edge] }
	second_arc := t.arc_uv[edge]; if first_arc == t.arc_uv[edge] { second_arc = t.arc_vu[edge] }
	root := ett_rotate(t,ett_root(t,first_arc),first_arc)
	drop, rest: int; ett_split(t,root,1,&drop,&rest)
	between, suffix: int; ett_split(t,rest,ett_position(t,second_arc),&between,&suffix)
	drop_second, other: int; ett_split(t,suffix,1,&drop_second,&other)
	if between >= 0 { t.parent[between] = -1 }; if other >= 0 { t.parent[other] = -1 }; t.active[edge] = false
}
ett_set_weight :: proc(t: ^Ett_Tree, vertex: int, value: i64) {
	t.value[vertex] = value; path: [NODES]int; count := 0; node := vertex
	for node >= 0 { path[count] = node; count += 1; node = t.parent[node] }
	for i in 0..<count { ett_pull(t,path[i]) }
}
ett_store :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value); for byte in 0..<8 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
euler_tour_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(INPUT_MAX) { return -1 }
	nr, mr := input[0], input[1]; if nr < 1 || nr > N || mr < 1 || mr > M { return -1 }
	n, m, cursor := int(nr), int(mr), 2; weights: [N]i64
	for i in 0..<n { if cursor >= int(length) { return -1 }; weights[i] = input[cursor]; cursor += 1; if weights[i] < -100 || weights[i] > 100 { return -1 } }
	ops: [M]Ett_Op; query_count := 0
	for i in 0..<m {
		if cursor >= int(length) { return -1 }; kind := input[cursor]; cursor += 1
		if kind == 0 || kind == 1 { if cursor+2 > int(length) { return -1 }; u,v := input[cursor],input[cursor+1]; cursor += 2; if u < 0 || u >= nr || v < 0 || v >= nr || u == v { return -1 }; ops[i] = {kind,u,v} }
		else if kind == 2 { if cursor+2 > int(length) { return -1 }; v,w := input[cursor],input[cursor+1]; cursor += 2; if v < 0 || v >= nr || w < -100 || w > 100 { return -1 }; ops[i] = {kind,v,w} }
		else if kind == 3 { if cursor >= int(length) { return -1 }; v := input[cursor]; cursor += 1; if v < 0 || v >= nr { return -1 }; ops[i] = {kind,v,0}; query_count += 1 }
		else { return -1 }
	}
	if cursor != int(length) || query_count == 0 { return -1 }
	adj: [N*N]bool
	for i in 0..<m { op := ops[i]; u,v := int(op.a),int(op.b)
		if op.kind == 0 { if ett_connected(&adj[0],u,v,n) { return -1 }; adj[u*N+v] = true; adj[v*N+u] = true }
		else if op.kind == 1 { if !adj[u*N+v] { return -1 }; adj[u*N+v] = false; adj[v*N+u] = false }
	}
	required := c.size_t(16*query_count); if output == nil || capacity < required { return -2 }
	tree: Ett_Tree; ett_initialize(&tree,weights,n); answers: [2*M]i64; answer_count := 0
	for i in 0..<m { op := ops[i]; a,b := int(op.a),int(op.b)
		if op.kind == 0 { ett_link(&tree,a,b) } else if op.kind == 1 { ett_cut(&tree,a,b) } else if op.kind == 2 { ett_set_weight(&tree,a,op.b) }
		else { root := ett_root(&tree,a); answers[answer_count] = i64(tree.count[root]); answers[answer_count+1] = tree.total[root]; answer_count += 2 }
	}
	for i in 0..<answer_count { ett_store(output,8*i,answers[i]) }; return i64(required)
}
