package dynamic_tree_vertex_set_path_composite

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 8
MAX_Q :: 12
MAX_INPUT :: 93

Affine :: struct { multiplier, addend: i64 }
Lct_Node :: struct {
	child: [2]int
	parent: int
	reversed: bool
	value, forward, backward: Affine
}
Query :: struct { kind, a, b, c, d: i64 }

identity :: proc "contextless" () -> Affine { return Affine{1, 0} }
compose :: proc "contextless" (after, before: Affine) -> Affine {
	return Affine{after.multiplier * before.multiplier % MODULUS,
		(after.multiplier * before.addend + after.addend) % MODULUS}
}
is_aux_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) -> bool {
	p := nodes^[x].parent
	return p < 0 || (nodes^[p].child[0] != x && nodes^[p].child[1] != x)
}
pull :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	lf := identity(); rf := identity(); lb := identity(); rb := identity()
	if nodes^[x].child[0] >= 0 {
		lf = nodes^[nodes^[x].child[0]].forward
		lb = nodes^[nodes^[x].child[0]].backward
	}
	if nodes^[x].child[1] >= 0 {
		rf = nodes^[nodes^[x].child[1]].forward
		rb = nodes^[nodes^[x].child[1]].backward
	}
	nodes^[x].forward = compose(rf, compose(nodes^[x].value, lf))
	nodes^[x].backward = compose(lb, compose(nodes^[x].value, rb))
}
reverse_path :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	if x < 0 do return
	temp := nodes^[x].child[0]
	nodes^[x].child[0] = nodes^[x].child[1]
	nodes^[x].child[1] = temp
	temp_affine := nodes^[x].forward
	nodes^[x].forward = nodes^[x].backward
	nodes^[x].backward = temp_affine
	nodes^[x].reversed = !nodes^[x].reversed
}
push :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	if !nodes^[x].reversed do return
	reverse_path(nodes, nodes^[x].child[0])
	reverse_path(nodes, nodes^[x].child[1])
	nodes^[x].reversed = false
}
rotate :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	p := nodes^[x].parent
	g := nodes^[p].parent
	right_child := nodes^[p].child[1] == x
	middle := nodes^[x].child[0]
	if !right_child do middle = nodes^[x].child[1]
	if !is_aux_root(nodes, p) {
		if nodes^[g].child[0] == p do nodes^[g].child[0] = x else nodes^[g].child[1] = x
	}
	nodes^[x].parent = g
	if right_child { nodes^[x].child[0] = p; nodes^[p].child[1] = middle }
	else { nodes^[x].child[1] = p; nodes^[p].child[0] = middle }
	nodes^[p].parent = x
	if middle >= 0 do nodes^[middle].parent = p
	pull(nodes, p); pull(nodes, x)
}
splay :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	stack: [MAX_N]int
	count := 0
	y := x
	stack[count] = y; count += 1
	for !is_aux_root(nodes, y) { y = nodes^[y].parent; stack[count] = y; count += 1 }
	for count > 0 { count -= 1; push(nodes, stack[count]) }
	for !is_aux_root(nodes, x) {
		p := nodes^[x].parent
		if !is_aux_root(nodes, p) {
			g := nodes^[p].parent
			zigzig := (nodes^[p].child[0] == x) == (nodes^[g].child[0] == p)
			if zigzig do rotate(nodes, p) else rotate(nodes, x)
		}
		rotate(nodes, x)
	}
}
access :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) {
	last := -1
	y := x
	for y >= 0 {
		splay(nodes, y)
		nodes^[y].child[1] = last
		if last >= 0 do nodes^[last].parent = y
		pull(nodes, y); last = y; y = nodes^[y].parent
	}
	splay(nodes, x)
}
make_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x: int) { access(nodes, x); reverse_path(nodes, x) }
find_root :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, x_value: int) -> int {
	x := x_value
	access(nodes, x); push(nodes, x)
	for nodes^[x].child[0] >= 0 { x = nodes^[x].child[0]; push(nodes, x) }
	splay(nodes, x)
	return x
}
link_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> bool {
	if u == v do return false
	make_root(nodes, u)
	if find_root(nodes, v) == u do return false
	nodes^[u].parent = v
	return true
}
cut_nodes :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int) -> bool {
	if u == v do return false
	make_root(nodes, u); access(nodes, v)
	if nodes^[v].child[0] != u || nodes^[u].child[1] >= 0 do return false
	nodes^[v].child[0] = -1; nodes^[u].parent = -1; pull(nodes, v)
	return true
}
set_value :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, vertex: int, value: Affine) {
	access(nodes, vertex); nodes^[vertex].value = value; pull(nodes, vertex)
}
path_composition :: proc "contextless" (nodes: ^[MAX_N]Lct_Node, u, v: int, result: ^Affine) -> bool {
	make_root(nodes, u)
	if find_root(nodes, v) != u do return false
	make_root(nodes, u); access(nodes, v); result^ = nodes^[v].forward
	return true
}
find_dsu :: proc "contextless" (parent: ^[MAX_N]usize, item_value: usize) -> usize {
	item := item_value
	for parent^[item] != item { parent^[item] = parent^[parent^[item]]; item = parent^[item] }
	return item
}
connected :: proc "contextless" (adjacency: ^[MAX_N * MAX_N]bool, n, start, target: usize) -> bool {
	seen: [MAX_N]bool
	stack: [MAX_N]usize
	top := 1; seen[start] = true; stack[0] = start
	for top > 0 {
		top -= 1; u := stack[top]
		if u == target do return true
		for v := 0; v < n; v += 1 {
			if adjacency^[u * MAX_N + v] && !seen[v] { seen[v] = true; stack[top] = v; top += 1 }
		}
	}
	return false
}
store_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
dynamic_tree_vertex_set_path_composite :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_Q do return -1
	n := usize(input[0]); q := usize(input[1])
	if length < 2 + 2 * n + 2 * (n - 1) + 4 * q do return -1
	values: [MAX_N]Affine
	for i := 0; i < n; i += 1 {
		m := input[2 + 2 * i]; b := input[3 + 2 * i]
		if m < 1 || m >= MODULUS || b < 0 || b >= MODULUS do return -1
		values[i] = Affine{m, b}
	}
	adjacency: [MAX_N * MAX_N]bool
	dsu: [MAX_N]usize
	edge_u, edge_v: [MAX_N]usize
	for i := 0; i < n; i += 1 { dsu[i] = i }
	cursor := usize(2 + 2 * n)
	for edge := 0; edge + 1 < n; edge += 1 {
		uv := input[cursor]; vv := input[cursor + 1]; cursor += 2
		if uv < 0 || uv >= i64(n) || vv < 0 || vv >= i64(n) || uv == vv do return -1
		u := usize(uv); v := usize(vv)
		ru := find_dsu(&dsu, u); rv := find_dsu(&dsu, v)
		if ru == rv do return -1
		dsu[rv] = ru; adjacency[u * MAX_N + v] = true; adjacency[v * MAX_N + u] = true
		edge_u[edge] = u; edge_v[edge] = v
	}
	queries: [MAX_Q]Query
	answer_count := usize(0)
	for i := 0; i < q; i += 1 {
		if cursor >= length do return -1
		current := Query{input[cursor], 0, 0, 0, 0}; cursor += 1
		if current.kind == 0 {
			if length - cursor < 4 do return -1
			current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; current.d=input[cursor+3]; cursor += 4
			if current.a<0 || current.a>=i64(n) || current.b<0 || current.b>=i64(n) || current.c<0 || current.c>=i64(n) || current.d<0 || current.d>=i64(n) || current.a==current.b || current.c==current.d do return -1
			u:=usize(current.a); v:=usize(current.b); w:=usize(current.c); x:=usize(current.d)
			if !adjacency[u*MAX_N+v] do return -1
			adjacency[u*MAX_N+v]=false; adjacency[v*MAX_N+u]=false
			if connected(&adjacency,n,w,x) do return -1
			adjacency[w*MAX_N+x]=true; adjacency[x*MAX_N+w]=true
		} else if current.kind == 1 {
			if length - cursor < 3 do return -1
			current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; cursor += 3
			if current.a<0 || current.a>=i64(n) || current.b<1 || current.b>=MODULUS || current.c<0 || current.c>=MODULUS do return -1
		} else if current.kind == 2 {
			if length - cursor < 3 do return -1
			current.a=input[cursor]; current.b=input[cursor+1]; current.c=input[cursor+2]; cursor += 3
			if current.a<0 || current.a>=i64(n) || current.b<0 || current.b>=i64(n) || current.c<0 || current.c>=MODULUS do return -1
			answer_count += 1
		} else { return -1 }
		queries[i] = current
	}
	if cursor != length do return -1
	required := 8 * answer_count
	if output == nil || capacity < c.size_t(required) do return -2
	nodes: [MAX_N]Lct_Node
	for i := 0; i < n; i += 1 {
		nodes[i].child = {-1,-1}; nodes[i].parent = -1; nodes[i].value = values[i]
		nodes[i].forward = values[i]; nodes[i].backward = values[i]
	}
	for edge := 0; edge + 1 < n; edge += 1 { if !link_nodes(&nodes, int(edge_u[edge]), int(edge_v[edge])) do return -1 }
	answers: [MAX_Q]i64
	written := usize(0)
	for i := 0; i < q; i += 1 {
		z := queries[i]
		if z.kind == 0 {
			if !cut_nodes(&nodes,int(z.a),int(z.b)) || !link_nodes(&nodes,int(z.c),int(z.d)) do return -1
		} else if z.kind == 1 { set_value(&nodes,int(z.a),Affine{z.b,z.c}) }
		else {
			combined: Affine
			if !path_composition(&nodes,int(z.a),int(z.b),&combined) do return -1
			answers[written]=(combined.multiplier*z.c+combined.addend)%MODULUS; written += 1
		}
	}
	for i := 0; i < written; i += 1 { store_le(output,int(8*i),answers[i]) }
	return i64(required)
}
