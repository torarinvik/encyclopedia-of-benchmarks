module dynamic_tree_vertex_add_subtree_sum

const max_n = 32
const max_q = 64
const max_input = 3 * max_n + 5 * max_q + 1
const max_value = i64(1000)

struct LctNode {
mut:
	left int
	right int
	parent int
	reversed bool
	value i64
	virtual_sum i64
	sum i64
}

fn lct_is_root(nodes [max_n]LctNode, x int) bool {
	p := nodes[x].parent
	return p < 0 || (nodes[p].left != x && nodes[p].right != x)
}
fn lct_sum(nodes [max_n]LctNode, x int) i64 {
	if x < 0 { return 0 }
	return nodes[x].sum
}
fn lct_pull(mut nodes [max_n]LctNode, x int) {
	nodes[x].sum = nodes[x].value + nodes[x].virtual_sum + lct_sum(nodes, nodes[x].left) + lct_sum(nodes, nodes[x].right)
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
	if !lct_is_root(nodes, p) {
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
	for !lct_is_root(nodes, y) {
		y = nodes[y].parent
		stack[count] = y
		count++
	}
	for count > 0 {
		count--
		lct_push(mut nodes, stack[count])
	}
	for !lct_is_root(nodes, x) {
		p := nodes[x].parent
		if !lct_is_root(nodes, p) {
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
		old_right := nodes[y].right
		nodes[y].virtual_sum += lct_sum(nodes, old_right) - lct_sum(nodes, last)
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
fn lct_link(mut nodes [max_n]LctNode, u int, v int) bool {
	if u == v { return false }
	lct_make_root(mut nodes, u)
	if lct_find_root(mut nodes, v) == u { return false }
	lct_access(mut nodes, v)
	nodes[u].parent = v
	nodes[v].virtual_sum += nodes[u].sum
	lct_pull(mut nodes, v)
	return true
}
fn lct_cut(mut nodes [max_n]LctNode, u int, v int) bool {
	if u == v { return false }
	lct_make_root(mut nodes, u)
	lct_access(mut nodes, v)
	if nodes[v].left != u || nodes[u].right >= 0 { return false }
	nodes[v].left = -1
	nodes[u].parent = -1
	lct_pull(mut nodes, v)
	return true
}
fn lct_subtree_sum(mut nodes [max_n]LctNode, vertex int, parent int) i64 {
	lct_make_root(mut nodes, parent)
	lct_access(mut nodes, vertex)
	if nodes[vertex].left != parent || nodes[parent].right >= 0 { return -1 }
	return nodes[vertex].value + nodes[vertex].virtual_sum
}
fn lct_put_i64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'dynamic_tree_vertex_add_subtree_sum']
pub fn dynamic_tree_vertex_add_subtree_sum(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > usize(max_input) { return -1 }
		n_value := input[0]
		q_value := input[1]
		if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
		n := int(n_value)
		q := int(q_value)
		if input_length != usize(3 * n + 5 * q) { return -1 }
		for i in 0 .. n { if input[2 + i] < 0 || input[2 + i] > max_value { return -1 } }
		edge_start := 2 + n
		operation_start := edge_start + 2 * (n - 1)
		for i in 0 .. (n - 1) {
			u := input[edge_start + 2 * i]
			v := input[edge_start + 2 * i + 1]
			if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v { return -1 }
		}
		for i in 0 .. q {
			at := operation_start + 5 * i
			kind := input[at]
			a := input[at + 1]
			b := input[at + 2]
			c := input[at + 3]
			d := input[at + 4]
			if kind == 0 {
				if a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value || d < 0 || d >= n_value || a == b || c == d { return -1 }
			} else if kind == 1 {
				if a < 0 || a >= n_value || b < 0 || b > max_value || c != 0 || d != 0 { return -1 }
			} else if kind == 2 {
				if a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0 { return -1 }
			} else { return -1 }
		}
		mut nodes := [max_n]LctNode{}
		for i in 0 .. n {
			nodes[i].left = -1
			nodes[i].right = -1
			nodes[i].parent = -1
			nodes[i].value = input[2 + i]
			nodes[i].sum = nodes[i].value
		}
		for i in 0 .. (n - 1) {
			if !lct_link(mut nodes, int(input[edge_start + 2 * i]), int(input[edge_start + 2 * i + 1])) { return -1 }
		}
		mut answers := [max_q]i64{}
		mut answer_count := 0
		for i in 0 .. q {
			at := operation_start + 5 * i
			kind := int(input[at])
			a := int(input[at + 1])
			b := int(input[at + 2])
			if kind == 0 {
				c := int(input[at + 3])
				d := int(input[at + 4])
				if !lct_cut(mut nodes, a, b) || !lct_link(mut nodes, c, d) { return -1 }
			} else if kind == 1 {
				lct_access(mut nodes, a)
				nodes[a].value += i64(b)
				lct_pull(mut nodes, a)
			} else {
				answer := lct_subtree_sum(mut nodes, a, b)
				if answer < 0 { return -1 }
				answers[answer_count] = answer
				answer_count++
			}
		}
		output_bytes := 8 * answer_count
		if output_bytes > 0 && (output == nil || int(output_capacity) < output_bytes) { return -2 }
		for i in 0 .. answer_count { lct_put_i64(mut output, 8 * i, answers[i]) }
		return i64(output_bytes)
	}
}
