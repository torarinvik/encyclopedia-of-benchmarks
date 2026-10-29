module link_cut_tree

const max_n = 16
const max_q = 64
const max_input = 210

struct LctNode {
mut:
	left int
	right int
	parent int
	reversed bool
	value i64
	sum i64
}

fn lct_is_root(mut nodes [max_n]LctNode, x int) bool {
	p := nodes[x].parent
	return p < 0 || (nodes[p].left != x && nodes[p].right != x)
}
fn lct_pull(mut nodes [max_n]LctNode, x int) {
	left_sum := if nodes[x].left < 0 { i64(0) } else { nodes[nodes[x].left].sum }
	right_sum := if nodes[x].right < 0 { i64(0) } else { nodes[nodes[x].right].sum }
	nodes[x].sum = nodes[x].value + left_sum + right_sum
}
fn lct_reverse(mut nodes [max_n]LctNode, x int) {
	if x < 0 { return }
	temp := nodes[x].left
	nodes[x].left = nodes[x].right
	nodes[x].right = temp
	nodes[x].reversed = !nodes[x].reversed
}
fn lct_push(mut nodes [max_n]LctNode, x int) {
	if !nodes[x].reversed { return }
	lct_reverse(mut nodes, nodes[x].left)
	lct_reverse(mut nodes, nodes[x].right)
	nodes[x].reversed = false
}
fn lct_rotate(mut nodes [max_n]LctNode, x int) {
	p := nodes[x].parent
	g := nodes[p].parent
	right_child := nodes[p].right == x
	middle := if right_child { nodes[x].left } else { nodes[x].right }
	if !lct_is_root(mut nodes, p) {
		if nodes[g].left == p { nodes[g].left = x } else { nodes[g].right = x }
	}
	nodes[x].parent = g
	if right_child {
		nodes[x].left = p
		nodes[p].right = middle
	} else {
		nodes[x].right = p
		nodes[p].left = middle
	}
	nodes[p].parent = x
	if middle >= 0 { nodes[middle].parent = p }
	lct_pull(mut nodes, p)
	lct_pull(mut nodes, x)
}
fn lct_splay(mut nodes [max_n]LctNode, x int) {
	mut stack := [max_n]int{}
	mut count := 0
	mut y := x
	stack[count] = y
	count++
	for !lct_is_root(mut nodes, y) {
		y = nodes[y].parent
		stack[count] = y
		count++
	}
	for count > 0 {
		count--
		lct_push(mut nodes, stack[count])
	}
	for !lct_is_root(mut nodes, x) {
		p := nodes[x].parent
		if !lct_is_root(mut nodes, p) {
			g := nodes[p].parent
			zigzig := (nodes[p].left == x) == (nodes[g].left == p)
			lct_rotate(mut nodes, if zigzig { p } else { x })
		}
		lct_rotate(mut nodes, x)
	}
}
fn lct_access(mut nodes [max_n]LctNode, x int) {
	mut last := -1
	mut y := x
	for y >= 0 {
		lct_splay(mut nodes, y)
		nodes[y].right = last
		if last >= 0 { nodes[last].parent = y }
		lct_pull(mut nodes, y)
		last = y
		y = nodes[y].parent
	}
	lct_splay(mut nodes, x)
}
fn lct_make_root(mut nodes [max_n]LctNode, x int) {
	lct_access(mut nodes, x)
	lct_reverse(mut nodes, x)
}
fn lct_find_root(mut nodes [max_n]LctNode, x int) int {
	lct_access(mut nodes, x)
	lct_push(mut nodes, x)
	mut root := x
	for nodes[root].left >= 0 {
		root = nodes[root].left
		lct_push(mut nodes, root)
	}
	lct_splay(mut nodes, root)
	return root
}
fn lct_link(mut nodes [max_n]LctNode, u int, v int) i64 {
	if u == v { return 0 }
	lct_make_root(mut nodes, u)
	if lct_find_root(mut nodes, v) == u { return 0 }
	nodes[u].parent = v
	return 1
}
fn lct_cut(mut nodes [max_n]LctNode, u int, v int) i64 {
	if u == v { return 0 }
	lct_make_root(mut nodes, u)
	lct_access(mut nodes, v)
	if nodes[v].left != u || nodes[u].right >= 0 { return 0 }
	nodes[v].left = -1
	nodes[u].parent = -1
	lct_pull(mut nodes, v)
	return 1
}
fn lct_path_sum(mut nodes [max_n]LctNode, u int, v int) i64 {
	lct_make_root(mut nodes, u)
	if lct_find_root(mut nodes, v) != u { return -1 }
	lct_make_root(mut nodes, u)
	lct_access(mut nodes, v)
	return nodes[v].sum
}
fn lct_put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'link_cut_tree']
pub fn link_cut_tree(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > usize(max_input) { return -1 }
		n_value := input[0]
		q_value := input[1]
		if n_value < 1 || n_value > max_n || q_value < 1 || q_value > max_q { return -1 }
		n := int(n_value)
		q := int(q_value)
		if input_length != usize(2 + n + 3 * q) { return -1 }
		for i in 0 .. n {
			if input[2 + i] < 0 || input[2 + i] > 1000000 { return -1 }
		}
		operations_at := 2 + n
		for i in 0 .. q {
			at := operations_at + 3 * i
			op := input[at]
			u := input[at + 1]
			v := input[at + 2]
			if op < 0 || op > 2 || u < 0 || u >= n_value || v < 0 || v >= n_value { return -1 }
		}
		bytes := 8 * q
		if output == nil || output_capacity < usize(bytes) { return -2 }
		mut nodes := [max_n]LctNode{}
		for i in 0 .. n {
			nodes[i].left = -1
			nodes[i].right = -1
			nodes[i].parent = -1
			nodes[i].value = input[2 + i]
			nodes[i].sum = nodes[i].value
		}
		for i in 0 .. q {
			at := operations_at + 3 * i
			op := int(input[at])
			u := int(input[at + 1])
			v := int(input[at + 2])
			result := if op == 0 { lct_link(mut nodes, u, v) } else if op == 1 { lct_cut(mut nodes, u, v) } else { lct_path_sum(mut nodes, u, v) }
			lct_put_i64(mut output, 8 * i, result)
		}
		return i64(bytes)
	}
}
