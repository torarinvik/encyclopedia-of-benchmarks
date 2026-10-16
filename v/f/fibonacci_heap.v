module fibonacci_heap

struct HeapNode {
	mut:
	key i64
	degree int
	parent int
	child int
	left int
	right int
}

fn remove_node(mut nodes [128]HeapNode, x int) {
	nodes[nodes[x].left].right = nodes[x].right
	nodes[nodes[x].right].left = nodes[x].left
}
fn add_root(mut nodes [128]HeapNode, minimum int, x int) int {
	nodes[x].parent = -1
	if minimum == -1 { nodes[x].left = x; nodes[x].right = x; return x }
	r := nodes[minimum].right
	nodes[x].left = minimum; nodes[x].right = r; nodes[minimum].right = x; nodes[r].left = x
	if nodes[x].key < nodes[minimum].key { return x }
	return minimum
}
fn link_child(mut nodes [128]HeapNode, parent int, child int) {
	remove_node(mut nodes, child)
	nodes[child].parent = parent
	if nodes[parent].child == -1 { nodes[child].left = child; nodes[child].right = child; nodes[parent].child = child }
	else { c := nodes[parent].child; r := nodes[c].right; nodes[child].left = c; nodes[child].right = r; nodes[c].right = child; nodes[r].left = child }
	nodes[parent].degree++
}
fn consolidate(mut nodes [128]HeapNode, minimum int) int {
	if minimum == -1 { return -1 }
	mut roots := [128]int{}; mut count := 0; mut x := minimum
	for { roots[count] = x; count++; x = nodes[x].right; if x == minimum { break } }
	mut table := [129]int{}; for i in 0 .. 129 { table[i] = -1 }
	for root in roots[..count] {
		if nodes[root].parent != -1 { continue }
		x = root; mut d := nodes[x].degree
		for table[d] != -1 { mut y := table[d]; if nodes[y].key < nodes[x].key { x, y = y, x }; table[d] = -1; link_child(mut nodes, x, y); d = nodes[x].degree }
		table[d] = x
	}
	mut new_minimum := -1
	for root in table { if root != -1 { new_minimum = add_root(mut nodes, new_minimum, root) } }
	return new_minimum
}
fn store_le(mut output &u8, offset int, value i64) {
	unsafe { mut bits := u64(value); for b in 0 .. 8 { output[offset+b] = u8(bits & 255); bits >>= 8 } }
}

@[export: 'fibonacci_heap']
pub fn fibonacci_heap(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if (length > 0 && unsafe { input == nil }) || length > 128 { return -1 }
	unsafe { for i in 0 .. int(length) { if input[i] < -2_147_483_648 || input[i] > 2_147_483_647 { return -1 } } }
	if capacity < length * 8 || (length > 0 && unsafe { output == nil }) { return -2 }
	if length == 0 { return 0 }
	unsafe {
		mut nodes := [128]HeapNode{}
		mut minimum := -1
		for i in 0 .. int(length) { nodes[i].key = input[i]; nodes[i].child = -1; nodes[i].left = i; nodes[i].right = i; minimum = add_root(mut nodes, minimum, i) }
		for out in 0 .. int(length) {
			z := minimum; store_le(mut output, out * 8, nodes[z].key)
			child := nodes[z].child
			if child != -1 { mut children := [128]int{}; mut n := 0; mut c := child; for { children[n] = c; n++; c = nodes[c].right; if c == child { break } }; for promoted in children[..n] { minimum = add_root(mut nodes, minimum, promoted) } }
			remove_node(mut nodes, z)
			if nodes[z].right == z { minimum = -1 } else { minimum = nodes[z].right; minimum = consolidate(mut nodes, minimum) }
		}
		return i64(length * 8)
	}
}
