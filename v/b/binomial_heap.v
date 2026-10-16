module binomial_heap

const max_ops = 128
const root_count = 9
const empty = -1

struct Node {
	value i64
	child int
	sibling int
	degree int
}

struct Heap {
mut:
	nodes []Node
	roots []int
	used int
	size int
}

fn link(mut h Heap, a int, b int) int {
	mut parent := a
	mut child := b
	if h.nodes[a].value >= h.nodes[b].value {
		parent = b
		child = a
	}
	h.nodes[child].sibling = h.nodes[parent].child
	h.nodes[parent].child = child
	h.nodes[parent].degree++
	return parent
}

fn add(mut h Heap, initial int) {
	mut root := initial
	mut degree := h.nodes[root].degree
	for h.roots[degree] != empty {
		root = link(mut h, root, h.roots[degree])
		h.roots[degree] = empty
		degree++
	}
	h.roots[degree] = root
}

fn insert(mut h Heap, value i64) {
	root := h.used
	h.used++
	h.nodes[root] = Node{value, empty, empty, 0}
	h.size++
	add(mut h, root)
}

fn minroot(h Heap) int {
	mut best := empty
	for root in h.roots {
		if root != empty && (best == empty || h.nodes[root].value < h.nodes[best].value) {
			best = root
		}
	}
	return best
}

fn extract(mut h Heap) i64 {
	best := minroot(h)
	degree := h.nodes[best].degree
	value := h.nodes[best].value
	h.roots[degree] = empty
	mut child := h.nodes[best].child
	for child != empty {
		next := h.nodes[child].sibling
		h.nodes[child].sibling = empty
		add(mut h, child)
		child = next
	}
	h.size--
	return value
}

fn put(output &u8, index int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[index * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'binomial_heap']
pub fn binomial_heap(input &i64, length usize, output &u8, capacity usize) i64 {
	if input == nil || length < 1 {
		return -1
	}
	unsafe {
		if input[0] < 0 || input[0] > max_ops {
			return -1
		}
		n := int(input[0])
		if length != usize(1 + 2 * n) {
			return -1
		}
		mut queries := 0
		mut size := 0
		for i in 0 .. n {
			op := input[1 + 2 * i]
			value := input[2 + 2 * i]
			if op == 0 {
				if value < -2147483648 || value > 2147483647 { return -1 }
				size++
			} else if op >= 1 && op <= 3 {
				if value != 0 || ((op == 1 || op == 2) && size == 0) { return -1 }
				if op == 2 { size-- }
				queries++
			} else { return -1 }
		}
		needed := queries * 8
		if capacity < usize(needed) || (needed > 0 && output == nil) { return -2 }
		mut heap := Heap{nodes: []Node{len: max_ops}, roots: []int{len: root_count, init: empty}}
		mut written := 0
		for i in 0 .. n {
			op := input[1 + 2 * i]
			value := input[2 + 2 * i]
			if op == 0 { insert(mut heap, value); continue }
			mut result := i64(0)
			if op == 1 { result = heap.nodes[minroot(heap)].value }
			else if op == 2 { result = extract(mut heap) }
			else if heap.size == 0 { result = 1 }
			put(output, written, result)
			written++
		}
		return i64(written)
	}
}
