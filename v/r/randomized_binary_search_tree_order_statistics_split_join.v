module randomized_binary_search_tree_order_statistics_split_join

import core:c

const max_input_length = 164

struct RbstState {
mut:
	keys [64]i64
	left [64]int
	right [64]int
	sizes [64]int
	used int
	random_state u32
}

fn tree_size(state &RbstState, root int) int {
	if root < 0 { return 0 }
	return state.sizes[root]
}

fn refresh(mut state RbstState, root int) {
	state.sizes[root] = 1 + tree_size(state, state.left[root]) + tree_size(state, state.right[root])
}

fn randbelow(mut state RbstState, bound u32) u32 {
	threshold := u32((u64(1) << 32) % u64(bound))
	for {
		state.random_state = u32((u64(state.random_state) * 1664525 + 1013904223) % 4294967296)
		raw := state.random_state
		if raw >= threshold { return raw % bound }
	}
	return 0
}

fn make_node(mut state RbstState, key i64, left int, right int) int {
	node := state.used
	state.used++
	state.keys[node] = key
	state.left[node] = left
	state.right[node] = right
	refresh(mut state, node)
	return node
}

fn split_tree(mut state RbstState, root int, pivot i64) (int, int) {
	if root < 0 { return -1, -1 }
	if state.keys[root] < pivot {
		low, high := split_tree(mut state, state.right[root], pivot)
		state.right[root] = low
		refresh(mut state, root)
		return root, high
	}
	low, high := split_tree(mut state, state.left[root], pivot)
	state.left[root] = high
	refresh(mut state, root)
	return low, root
}

fn join_trees(mut state RbstState, left int, right int) int {
	if left < 0 { return right }
	if right < 0 { return left }
	left_size := u32(tree_size(state, left))
	total := left_size + u32(tree_size(state, right))
	if randbelow(mut state, total) < left_size {
		state.right[left] = join_trees(mut state, state.right[left], right)
		refresh(mut state, left)
		return left
	}
	state.left[right] = join_trees(mut state, left, state.left[right])
	refresh(mut state, right)
	return right
}

fn contains(state &RbstState, root_start int, key i64) bool {
	mut root := root_start
	for root >= 0 {
		if state.keys[root] == key { return true }
		if key < state.keys[root] { root = state.left[root] } else { root = state.right[root] }
	}
	return false
}

fn insert_absent(mut state RbstState, root int, key i64) int {
	if root < 0 { return make_node(mut state, key, -1, -1) }
	if randbelow(mut state, u32(tree_size(state, root) + 1)) == 0 {
		low, high := split_tree(mut state, root, key)
		return make_node(mut state, key, low, high)
	}
	if key < state.keys[root] { state.left[root] = insert_absent(mut state, state.left[root], key) }
	else { state.right[root] = insert_absent(mut state, state.right[root], key) }
	refresh(mut state, root)
	return root
}

fn erase_key(mut state RbstState, root int, key i64) int {
	if root < 0 { return -1 }
	if key == state.keys[root] { return join_trees(mut state, state.left[root], state.right[root]) }
	if key < state.keys[root] { state.left[root] = erase_key(mut state, state.left[root], key) }
	else { state.right[root] = erase_key(mut state, state.right[root], key) }
	refresh(mut state, root)
	return root
}

fn kth(state &RbstState, root_start int, rank_start int) i64 {
	if rank_start > tree_size(state, root_start) { return -1 }
	mut root := root_start
	mut rank := rank_start
	for root >= 0 {
		left_size := tree_size(state, state.left[root])
		if rank == left_size + 1 { return state.keys[root] }
		if rank <= left_size { root = state.left[root] }
		else { rank -= left_size + 1; root = state.right[root] }
	}
	return -1
}

fn extreme(state &RbstState, root_start int, go_right bool) i64 {
	if root_start < 0 { return -1 }
	mut root := root_start
	for {
		link := if go_right { state.right[root] } else { state.left[root] }
		if link < 0 { return state.keys[root] }
		root = link
	}
	return -1
}

fn valid_operation(input &i64, offset int) bool {
	unsafe {
		op, a, b, c_value := input[offset], input[offset + 1], input[offset + 2], input[offset + 3]
		if op == 0 || op == 1 { return (a == 0 || a == 1) && b >= 0 && b <= 1000 && c_value == 0 }
		if op == 2 { return (a == 0 || a == 1) && b >= 1 && b <= 65 && c_value == 0 }
		if op == 3 { return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c_value >= 0 && c_value <= 1001 }
		if op == 4 { return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c_value == 0 }
	}
	return false
}

@[export: 'randomized_binary_search_tree_order_statistics_split_join']
pub fn randomized_binary_search_tree_order_statistics_split_join(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return -1 }
	unsafe {
		n, q, seed := input[0], input[1], input[2]
		if n < 0 || n > 32 || q < 0 || q > 32 || seed < 0 || seed > 4294967295 { return -1 }
		if length != usize(3 + n + 4 * q) { return -1 }
		for i in 0 .. usize(n) {
			if input[3 + i] < 0 || input[3 + i] > 1000 || (i > 0 && input[2 + i] >= input[3 + i]) { return -1 }
		}
		start := int(3 + n)
		for op in 0 .. int(q) { if !valid_operation(input, start + 4 * op) { return -1 } }
		mut state := RbstState{random_state: u32(seed)}
		mut roots := [-1, -1]
		for i in 0 .. int(n) { roots[0] = insert_absent(mut state, roots[0], input[3 + i]) }
		mut checksum := i64(0)
		mut query_number := i64(0)
		for op in 0 .. int(q) {
			offset := start + 4 * op
			code := input[offset]
			tree := int(input[offset + 1])
			arg, extra := input[offset + 2], input[offset + 3]
			if code == 0 {
				if !contains(state, roots[tree], arg) { roots[tree] = insert_absent(mut state, roots[tree], arg) }
			} else if code == 1 { roots[tree] = erase_key(mut state, roots[tree], arg) }
			else if code == 2 { query_number++; checksum += query_number * (kth(state, roots[tree], int(arg)) + 1) }
			else if code == 3 {
				destination := int(arg)
				if roots[destination] >= 0 { return -1 }
				low, high := split_tree(mut state, roots[tree], extra)
				roots[tree], roots[destination] = low, high
			} else {
				right_tree := int(arg)
				left_max := extreme(state, roots[tree], true)
				right_min := extreme(state, roots[right_tree], false)
				if left_max >= 0 && right_min >= 0 && left_max >= right_min { return -1 }
				roots[tree] = join_trees(mut state, roots[tree], roots[right_tree])
				roots[right_tree] = -1
			}
		}
		return checksum
	}
}
