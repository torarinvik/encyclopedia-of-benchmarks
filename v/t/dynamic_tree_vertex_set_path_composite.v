module dynamic_tree_vertex_set_path_composite

const max_n = 8
const max_q = 12
const max_input = 93
const modulus = i64(998244353)

struct Affine {
	multiplier i64
	addend i64
}

struct Node {
mut:
	child [2]int
	parent int
	reversed bool
	value Affine
	forward Affine
	backward Affine
}

struct Query {
	kind i64
	a i64
	b i64
	c i64
	d i64
}

fn identity() Affine { return Affine{multiplier: 1, addend: 0} }

fn compose(after Affine, before Affine) Affine {
	return Affine{
		multiplier: after.multiplier * before.multiplier % modulus
		addend: (after.multiplier * before.addend + after.addend) % modulus
	}
}

fn is_aux_root(mut nodes [max_n]Node, x int) bool {
	p := nodes[x].parent
	return p < 0 || (nodes[p].child[0] != x && nodes[p].child[1] != x)
}

fn pull(mut nodes [max_n]Node, x int) {
	left := nodes[x].child[0]
	right := nodes[x].child[1]
	lf := if left < 0 { identity() } else { nodes[left].forward }
	rf := if right < 0 { identity() } else { nodes[right].forward }
	lb := if left < 0 { identity() } else { nodes[left].backward }
	rb := if right < 0 { identity() } else { nodes[right].backward }
	nodes[x].forward = compose(rf, compose(nodes[x].value, lf))
	nodes[x].backward = compose(lb, compose(nodes[x].value, rb))
}

fn reverse_path(mut nodes [max_n]Node, x int) {
	if x < 0 { return }
	temp := nodes[x].child[0]
	nodes[x].child[0] = nodes[x].child[1]
	nodes[x].child[1] = temp
	affine_temp := nodes[x].forward
	nodes[x].forward = nodes[x].backward
	nodes[x].backward = affine_temp
	nodes[x].reversed = !nodes[x].reversed
}

fn push(mut nodes [max_n]Node, x int) {
	if !nodes[x].reversed { return }
	reverse_path(mut nodes, nodes[x].child[0])
	reverse_path(mut nodes, nodes[x].child[1])
	nodes[x].reversed = false
}

fn rotate(mut nodes [max_n]Node, x int) {
	p := nodes[x].parent
	g := nodes[p].parent
	direction := if nodes[p].child[1] == x { 1 } else { 0 }
	middle := nodes[x].child[direction ^ 1]
	if !is_aux_root(mut nodes, p) {
		if nodes[g].child[1] == p { nodes[g].child[1] = x } else { nodes[g].child[0] = x }
	}
	nodes[x].parent = g
	nodes[x].child[direction ^ 1] = p
	nodes[p].parent = x
	nodes[p].child[direction] = middle
	if middle >= 0 { nodes[middle].parent = p }
	pull(mut nodes, p)
	pull(mut nodes, x)
}

fn splay(mut nodes [max_n]Node, x int) {
	mut stack := [max_n]int{}
	mut count := 1
	mut y := x
	stack[0] = y
	for !is_aux_root(mut nodes, y) {
		y = nodes[y].parent
		stack[count] = y
		count++
	}
	for count > 0 {
		count--
		push(mut nodes, stack[count])
	}
	for !is_aux_root(mut nodes, x) {
		p := nodes[x].parent
		if !is_aux_root(mut nodes, p) {
			g := nodes[p].parent
			zigzig := (nodes[p].child[0] == x) == (nodes[g].child[0] == p)
			rotate(mut nodes, if zigzig { p } else { x })
		}
		rotate(mut nodes, x)
	}
}

fn access(mut nodes [max_n]Node, x int) {
	mut last := -1
	mut y := x
	for y >= 0 {
		splay(mut nodes, y)
		nodes[y].child[1] = last
		if last >= 0 { nodes[last].parent = y }
		pull(mut nodes, y)
		last = y
		y = nodes[y].parent
	}
	splay(mut nodes, x)
}

fn make_root(mut nodes [max_n]Node, x int) {
	access(mut nodes, x)
	reverse_path(mut nodes, x)
}

fn find_root(mut nodes [max_n]Node, x int) int {
	access(mut nodes, x)
	push(mut nodes, x)
	mut root := x
	for nodes[root].child[0] >= 0 {
		root = nodes[root].child[0]
		push(mut nodes, root)
	}
	splay(mut nodes, root)
	return root
}

fn link_nodes(mut nodes [max_n]Node, u int, v int) bool {
	if u == v { return false }
	make_root(mut nodes, u)
	if find_root(mut nodes, v) == u { return false }
	nodes[u].parent = v
	return true
}

fn cut_nodes(mut nodes [max_n]Node, u int, v int) bool {
	if u == v { return false }
	make_root(mut nodes, u)
	access(mut nodes, v)
	if nodes[v].child[0] != u || nodes[u].child[1] >= 0 { return false }
	nodes[v].child[0] = -1
	nodes[u].parent = -1
	pull(mut nodes, v)
	return true
}

fn set_value(mut nodes [max_n]Node, vertex int, value Affine) {
	access(mut nodes, vertex)
	nodes[vertex].value = value
	pull(mut nodes, vertex)
}

fn path_composition(mut nodes [max_n]Node, u int, v int) ?Affine {
	make_root(mut nodes, u)
	if find_root(mut nodes, v) != u { return none }
	make_root(mut nodes, u)
	access(mut nodes, v)
	return nodes[v].forward
}

fn find_dsu(mut parent [max_n]int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn connected(adjacency [max_n * max_n]bool, n int, start int, target int) bool {
	mut seen := [max_n]bool{}
	mut stack := [max_n]int{}
	mut top := 1
	seen[start] = true
	stack[0] = start
	for top > 0 {
		top--
		u := stack[top]
		if u == target { return true }
		for v in 0 .. n {
			if adjacency[u * max_n + v] && !seen[v] {
				seen[v] = true
				stack[top] = v
				top++
			}
		}
	}
	return false
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

@[export: 'dynamic_tree_vertex_set_path_composite']
pub fn dynamic_tree_vertex_set_path_composite(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		nv := input[0]
		qv := input[1]
		if nv < 1 || nv > max_n || qv < 1 || qv > max_q { return -1 }
		n := int(nv)
		q := int(qv)
		if length < usize(2 + 2 * n + 2 * (n - 1) + 4 * q) { return -1 }
		mut values := [max_n]Affine{}
		for vertex in 0 .. n {
			a := input[2 + 2 * vertex]
			b := input[3 + 2 * vertex]
			if a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			values[vertex] = Affine{multiplier: a, addend: b}
		}
		mut adjacency := [max_n * max_n]bool{}
		mut dsu := [max_n]int{}
		mut edge_u := [max_n]int{}
		mut edge_v := [max_n]int{}
		for vertex in 0 .. n { dsu[vertex] = vertex }
		mut cursor := 2 + 2 * n
		for edge in 0 .. (n - 1) {
			uv := input[cursor]
			vv := input[cursor + 1]
			cursor += 2
			if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv { return -1 }
			u := int(uv)
			v := int(vv)
			root_u := find_dsu(mut dsu, u)
			root_v := find_dsu(mut dsu, v)
			if root_u == root_v { return -1 }
			dsu[root_v] = root_u
			adjacency[u * max_n + v] = true
			adjacency[v * max_n + u] = true
			edge_u[edge] = u
			edge_v[edge] = v
		}
		mut queries := [max_q]Query{}
		mut answer_count := 0
		for query in 0 .. q {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]
			cursor++
			mut current := Query{kind: kind}
			if kind == 0 {
				if int(length) - cursor < 4 { return -1 }
				current.a = input[cursor]
				current.b = input[cursor + 1]
				current.c = input[cursor + 2]
				current.d = input[cursor + 3]
				cursor += 4
				if current.a < 0 || current.a >= nv || current.b < 0 || current.b >= nv || current.c < 0 || current.c >= nv || current.d < 0 || current.d >= nv || current.a == current.b || current.c == current.d { return -1 }
				u := int(current.a); v := int(current.b); w := int(current.c); x := int(current.d)
				if !adjacency[u * max_n + v] { return -1 }
				adjacency[u * max_n + v] = false
				adjacency[v * max_n + u] = false
				if connected(adjacency, n, w, x) { return -1 }
				adjacency[w * max_n + x] = true
				adjacency[x * max_n + w] = true
			} else if kind == 1 {
				if int(length) - cursor < 3 { return -1 }
				current.a = input[cursor]; current.b = input[cursor + 1]; current.c = input[cursor + 2]; cursor += 3
				if current.a < 0 || current.a >= nv || current.b < 1 || current.b >= modulus || current.c < 0 || current.c >= modulus { return -1 }
			} else if kind == 2 {
				if int(length) - cursor < 3 { return -1 }
				current.a = input[cursor]; current.b = input[cursor + 1]; current.c = input[cursor + 2]; cursor += 3
				if current.a < 0 || current.a >= nv || current.b < 0 || current.b >= nv || current.c < 0 || current.c >= modulus { return -1 }
				answer_count++
			} else { return -1 }
			queries[query] = current
		}
		if cursor != int(length) { return -1 }
		required := answer_count * 8
		if unsafe { output == nil } || capacity < usize(required) { return -2 }
		mut nodes := [max_n]Node{}
		for i in 0 .. max_n {
			nodes[i].child = [-1, -1]
			nodes[i].parent = -1
		}
		for i in 0 .. n {
			nodes[i].value = values[i]
			nodes[i].forward = values[i]
			nodes[i].backward = values[i]
		}
		for edge in 0 .. (n - 1) {
			if !link_nodes(mut nodes, edge_u[edge], edge_v[edge]) { return -1 }
		}
		mut answers := [max_q]i64{}
		mut written := 0
		for query in 0 .. q {
			current := queries[query]
			if current.kind == 0 {
				if !cut_nodes(mut nodes, int(current.a), int(current.b)) || !link_nodes(mut nodes, int(current.c), int(current.d)) { return -1 }
			} else if current.kind == 1 {
				set_value(mut nodes, int(current.a), Affine{multiplier: current.b, addend: current.c})
			} else {
				combined := path_composition(mut nodes, int(current.a), int(current.b)) or { return -1 }
				answers[written] = (combined.multiplier * current.c + combined.addend) % modulus
				written++
			}
		}
		for i in 0 .. written { store_i64_le(mut output, 8 * i, answers[i]) }
		return i64(required)
	}
}
