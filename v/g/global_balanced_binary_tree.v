module global_balanced_binary_tree

const max_n = 64
const max_parseable_length = 65

fn gbst_build_interval(lo int, hi int, path []int, prefix []int, mut gbst_parent []int,
	mut left_child []int, mut right_child []int, mut local_size []int) int {
	total_weight := prefix[hi] - prefix[lo]
	mut low := lo
	mut high := hi
	for high - low > 1 {
		middle := (low + high) / 2
		if 2 * (prefix[middle] - prefix[lo]) <= total_weight {
			low = middle
		} else {
			high = middle
		}
	}
	pivot := low
	node := path[pivot]
	local_size[node] = hi - lo
	if lo < pivot {
		child := gbst_build_interval(lo, pivot, path, prefix, mut gbst_parent,
			mut left_child, mut right_child, mut local_size)
		left_child[node] = child
		gbst_parent[child] = node
	}
	if pivot + 1 < hi {
		child := gbst_build_interval(pivot + 1, hi, path, prefix, mut gbst_parent,
			mut left_child, mut right_child, mut local_size)
		right_child[node] = child
		gbst_parent[child] = node
	}
	return node
}

@[export: 'global_balanced_binary_tree']
pub fn global_balanced_binary_tree(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_length) {
		return -1
	}
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	if length != usize(n_value) { return -1 }
	n := int(n_value)

	mut parent := [max_n]int{}
	mut subtree_size := [max_n]int{}
	mut heavy_child := [max_n]int{}
	mut gbst_parent := [max_n]int{}
	mut left_child := [max_n]int{}
	mut right_child := [max_n]int{}
	mut local_size := [max_n]int{}
	mut path := [max_n]int{}
	mut prefix := [max_n + 1]int{}
	for vertex in 0 .. n {
		parent[vertex] = -1
		subtree_size[vertex] = 1
		heavy_child[vertex] = -1
		gbst_parent[vertex] = -1
		left_child[vertex] = -1
		right_child[vertex] = -1
		local_size[vertex] = 0
	}
	for vertex in 1 .. n {
		p := unsafe { input[vertex] }
		if p < 0 || p >= i64(vertex) { return -1 }
		parent[vertex] = int(p)
	}

	mut cursor := n - 1
	for cursor > 0 {
		subtree_size[parent[cursor]] += subtree_size[cursor]
		cursor--
	}
	for vertex in 1 .. n {
		p := parent[vertex]
		current := heavy_child[p]
		if current < 0 || subtree_size[vertex] > subtree_size[current] {
			heavy_child[p] = vertex
		}
	}

	for head in 0 .. n {
		if head > 0 && heavy_child[parent[head]] == head { continue }
		mut path_length := 0
		mut vertex := head
		prefix[0] = 0
		for vertex < n {
			child := heavy_child[vertex]
			mut weight := subtree_size[vertex]
			if child >= 0 { weight -= subtree_size[child] }
			path[path_length] = vertex
			prefix[path_length + 1] = prefix[path_length] + weight
			path_length++
			if child < 0 { break }
			vertex = child
		}
		root := gbst_build_interval(0, path_length, path[..], prefix[..], mut gbst_parent[..],
			mut left_child[..], mut right_child[..], mut local_size[..])
		gbst_parent[root] = if head == 0 { -1 } else { parent[head] }
	}

	mut checksum := i64(0)
	for vertex in 0 .. n {
		record := i64(gbst_parent[vertex] + 1) + i64(65) * i64(left_child[vertex] + 1)
			+ i64(4225) * i64(right_child[vertex] + 1) + i64(274625) * i64(local_size[vertex])
		checksum += i64(vertex + 1) * record
	}
	return checksum
}
