module euler_tour_tree

import core:c

const ett_n = 8
const ett_m = 32
const ett_nodes = ett_n + 2 * ett_m
const ett_input_max = 2 + ett_n + 3 * ett_m

struct EttOp { kind i64; a i64; b i64 }
struct EttTree {
mut:
	left [ett_nodes]int
	right [ett_nodes]int
	parent [ett_nodes]int
	vertex [ett_nodes]int
	size [ett_nodes]int
	count [ett_nodes]int
	value [ett_nodes]i64
	total [ett_nodes]i64
	priority [ett_nodes]i64
	edge_u [ett_m]int
	edge_v [ett_m]int
	arc_uv [ett_m]int
	arc_vu [ett_m]int
	active [ett_m]bool
	next_node int
	edge_count int
}

fn (t &EttTree) node_size(node int) int { if node < 0 { return 0 }; return t.size[node] }
fn (t &EttTree) node_count(node int) int { if node < 0 { return 0 }; return t.count[node] }
fn (t &EttTree) node_total(node int) i64 { if node < 0 { return 0 }; return t.total[node] }
fn (mut t EttTree) pull(node int) {
	if node < 0 { return }
	t.size[node] = 1 + t.node_size(t.left[node]) + t.node_size(t.right[node])
	own := if t.vertex[node] >= 0 { 1 } else { 0 }
	t.count[node] = own + t.node_count(t.left[node]) + t.node_count(t.right[node])
	t.total[node] = t.value[node] + t.node_total(t.left[node]) + t.node_total(t.right[node])
}
fn (mut t EttTree) merge(a int, b int) int {
	if a < 0 { if b >= 0 { t.parent[b] = -1 }; return b }
	if b < 0 { t.parent[a] = -1; return a }
	if t.priority[a] > t.priority[b] {
		child := t.merge(t.right[a],b); t.right[a] = child
		if child >= 0 { t.parent[child] = a }; t.pull(a); t.parent[a] = -1; return a
	}
	child := t.merge(a,t.left[b]); t.left[b] = child
	if child >= 0 { t.parent[child] = b }; t.pull(b); t.parent[b] = -1; return b
}
fn (mut t EttTree) split(root int, prefix int) (int, int) {
	if root < 0 { return -1, -1 }
	if prefix <= t.node_size(t.left[root]) {
		first, rest := t.split(t.left[root],prefix); t.left[root] = rest
		if rest >= 0 { t.parent[rest] = root }; t.pull(root); t.parent[root] = -1
		if first >= 0 { t.parent[first] = -1 }; return first, root
	}
	left_size := t.node_size(t.left[root]); first, rest := t.split(t.right[root],prefix-left_size-1)
	t.right[root] = first; if first >= 0 { t.parent[first] = root }; t.pull(root); t.parent[root] = -1
	if rest >= 0 { t.parent[rest] = -1 }; return root, rest
}
fn (t &EttTree) root_of(node0 int) int { mut node := node0; for t.parent[node] >= 0 { node = t.parent[node] }; return node }
fn (t &EttTree) position(node0 int) int {
	mut node := node0; mut result := t.node_size(t.left[node])
	for t.parent[node] >= 0 { p := t.parent[node]; if t.right[p] == node { result += 1 + t.node_size(t.left[p]) }; node = p }
	return result
}
fn (mut t EttTree) rotate(root int, node int) int { first, rest := t.split(root,t.position(node)); return t.merge(rest,first) }
fn ett_connected(adjacency [ett_n * ett_n]bool, start int, target int, n int) bool {
	mut seen := [ett_n]bool{}; mut stack := [ett_n]int{}; mut top := 1; stack[0] = start; seen[start] = true
	for top > 0 { top--; u := stack[top]; if u == target { return true }
		for v in 0 .. n { if adjacency[u*ett_n+v] && !seen[v] { seen[v] = true; stack[top] = v; top++ } }
	}
	return false
}
fn (mut t EttTree) initialize(weights [ett_n]i64, n int) {
	for i in 0 .. ett_nodes { t.left[i] = -1; t.right[i] = -1; t.parent[i] = -1; t.vertex[i] = -1; t.priority[i] = (i*40503+17)%65521 }
	for i in 0 .. n { t.vertex[i] = i; t.value[i] = weights[i]; t.total[i] = weights[i]; t.size[i] = 1; t.count[i] = 1 }
	t.next_node = n; t.edge_count = 0
}
fn (mut t EttTree) link(u int, v int) {
	a := t.rotate(t.root_of(u),u); b := t.rotate(t.root_of(v),v); uv := t.next_node; vu := uv+1; t.next_node += 2
	for x in [uv,vu] { t.left[x] = -1; t.right[x] = -1; t.parent[x] = -1; t.vertex[x] = -1; t.value[x] = 0; t.total[x] = 0; t.size[x] = 1; t.count[x] = 0 }
	root := t.merge(t.merge(t.merge(a,uv),b),vu); t.parent[root] = -1
	e := t.edge_count; t.edge_count++; t.edge_u[e] = u; t.edge_v[e] = v; t.arc_uv[e] = uv; t.arc_vu[e] = vu; t.active[e] = true
}
fn (mut t EttTree) cut(u int, v int) {
	mut edge := -1
	if t.edge_count > 0 { for offset in 0 .. t.edge_count { i := t.edge_count-offset-1; if t.active[i] && ((t.edge_u[i] == u && t.edge_v[i] == v) || (t.edge_u[i] == v && t.edge_v[i] == u)) { edge = i; break } } }
	mut first_arc := t.arc_vu[edge]; if t.edge_u[edge] == u && t.edge_v[edge] == v { first_arc = t.arc_uv[edge] }
	second_arc := if first_arc == t.arc_uv[edge] { t.arc_vu[edge] } else { t.arc_uv[edge] }
	root := t.rotate(t.root_of(first_arc),first_arc); _, rest := t.split(root,1)
	between, suffix := t.split(rest,t.position(second_arc)); _, other := t.split(suffix,1)
	if between >= 0 { t.parent[between] = -1 }; if other >= 0 { t.parent[other] = -1 }; t.active[edge] = false
}
fn (mut t EttTree) set_weight(vertex int, value i64) {
	t.value[vertex] = value; mut path := [ett_nodes]int{}; mut count := 0; mut node := vertex
	for node >= 0 { path[count] = node; count++; node = t.parent[node] }
	for i in 0 .. count { t.pull(path[i]) }
}
fn ett_store(mut output &u8, offset int, value i64) {
	bits := u64(value); unsafe { for byte in 0 .. 8 { output[offset+byte] = u8((bits >> (8*byte)) & 255) } }
}

@[export: 'euler_tour_tree']
pub fn euler_tour_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > ett_input_max { return -1 }
		nr, mr := input[0], input[1]; if nr < 1 || nr > ett_n || mr < 1 || mr > ett_m { return -1 }
		n, m := int(nr), int(mr)
		mut cursor := 2
		mut weights := [ett_n]i64{}
		for i in 0 .. n { if cursor >= int(length) { return -1 }; weights[i] = input[cursor]; cursor++; if weights[i] < -100 || weights[i] > 100 { return -1 } }
		mut ops := [ett_m]EttOp{}; mut query_count := 0
		for i in 0 .. m {
			if cursor >= int(length) { return -1 }; kind := input[cursor]; cursor++
			if kind == 0 || kind == 1 { if cursor+2 > int(length) { return -1 }; u,v := input[cursor],input[cursor+1]; cursor += 2; if u < 0 || u >= nr || v < 0 || v >= nr || u == v { return -1 }; ops[i] = EttOp{kind,u,v} }
			else if kind == 2 { if cursor+2 > int(length) { return -1 }; v,w := input[cursor],input[cursor+1]; cursor += 2; if v < 0 || v >= nr || w < -100 || w > 100 { return -1 }; ops[i] = EttOp{kind,v,w} }
			else if kind == 3 { if cursor >= int(length) { return -1 }; v := input[cursor]; cursor++; if v < 0 || v >= nr { return -1 }; ops[i] = EttOp{kind,v,0}; query_count++ }
			else { return -1 }
		}
		if cursor != int(length) || query_count == 0 { return -1 }
		mut adjacency := [ett_n*ett_n]bool{}
		for i in 0 .. m { op := ops[i]; u,v := int(op.a),int(op.b); if op.kind == 0 { if ett_connected(adjacency,u,v,n) { return -1 }; adjacency[u*ett_n+v] = true; adjacency[v*ett_n+u] = true } else if op.kind == 1 { if !adjacency[u*ett_n+v] { return -1 }; adjacency[u*ett_n+v] = false; adjacency[v*ett_n+u] = false } }
		required := 16*query_count; if output == nil || capacity < usize(required) { return -2 }
		mut tree := EttTree{}; tree.initialize(weights,n); mut answers := [2*ett_m]i64{}; mut answer_count := 0
		for i in 0 .. m { op := ops[i]; a,b := int(op.a),int(op.b); if op.kind == 0 { tree.link(a,b) } else if op.kind == 1 { tree.cut(a,b) } else if op.kind == 2 { tree.set_weight(a,op.b) } else { root := tree.root_of(a); answers[answer_count] = i64(tree.count[root]); answers[answer_count+1] = tree.total[root]; answer_count += 2 } }
		for i in 0 .. answer_count { ett_store(mut output,8*i,answers[i]) }; return i64(required)
	}
}
