module range_union_find

const max_n = 32
const max_q = 32
const max_parseable_length = 99

fn find_root(mut parent []i64, vertex_input int) int {
	mut vertex := vertex_input
	for parent[vertex] >= 0 {
		ancestor := int(parent[vertex])
		if parent[ancestor] >= 0 { parent[vertex] = parent[ancestor] }
		vertex = ancestor
	}
	return vertex
}

fn unite_roots(mut parent []i64, mut left []i64, mut right []i64, root_a_input int, root_b_input int) int {
	mut root_a := root_a_input
	mut root_b := root_b_input
	if parent[root_a] > parent[root_b] {
		temporary := root_a
		root_a = root_b
		root_b = temporary
	}
	parent[root_a] += parent[root_b]
	parent[root_b] = i64(root_a)
	if left[root_b] < left[root_a] { left[root_a] = left[root_b] }
	if right[root_b] > right[root_a] { right[root_a] = right[root_b] }
	return root_a
}

@[export: 'range_union_find']
pub fn range_union_find(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > max_parseable_length { return -1 }
	n_value := unsafe { values[0] }
	q_value := unsafe { values[1] }
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q ||
		length != 2 + 3 * int(q_value) { return -1 }
	n := int(n_value)
	q := int(q_value)
	for operation in 0 .. q {
		offset := 2 + 3 * operation
		opcode := unsafe { values[offset] }
		first := unsafe { values[offset + 1] }
		second := unsafe { values[offset + 2] }
		if opcode == 0 {
			if first < 0 || first > second || second > n_value { return -1 }
		} else if opcode == 1 {
			if first < 0 || first >= n_value || second < 0 || second >= n_value { return -1 }
		} else if opcode == 2 {
			if first < 0 || first >= n_value || second != 0 { return -1 }
		} else { return -1 }
	}
	mut parent := []i64{len: n}
	mut left := []i64{len: n}
	mut right := []i64{len: n}
	for vertex in 0 .. n {
		parent[vertex] = -1
		left[vertex] = i64(vertex)
		right[vertex] = i64(vertex + 1)
	}
	mut components := n
	mut total := i64(0)
	for operation in 0 .. q {
		offset := 2 + 3 * operation
		opcode := int(unsafe { values[offset] })
		first := int(unsafe { values[offset + 1] })
		second := int(unsafe { values[offset + 2] })
		mut observed := i64(0)
		if opcode == 0 {
			if first < second {
				mut root := find_root(mut parent, first)
				mut next := int(right[root])
				for next < second {
					next_root := find_root(mut parent, next)
					if root == next_root { break }
					root = unite_roots(mut parent, mut left, mut right, root, next_root)
					components--
					next = int(right[root])
				}
			}
			observed = i64(components)
		} else if opcode == 1 {
			if find_root(mut parent, first) == find_root(mut parent, second) { observed = 1 }
		} else {
			observed = -parent[find_root(mut parent, first)]
		}
		total += i64(operation + 1) * observed
	}
	return total
}
