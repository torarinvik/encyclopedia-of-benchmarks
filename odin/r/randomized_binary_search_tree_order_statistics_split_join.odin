package randomized_binary_search_tree_order_statistics_split_join

import "core:c"

Node :: struct { key: i64, left: int, right: int, size: int }
State :: struct { nodes: [64]Node, used: int, random_state: u32 }

tree_size :: proc(state: ^State, root: int) -> int {
	if root < 0 do return 0
	return state.nodes[root].size
}

refresh :: proc(state: ^State, root: int) {
	state.nodes[root].size = 1 + tree_size(state, state.nodes[root].left) + tree_size(state, state.nodes[root].right)
}

randbelow :: proc(state: ^State, bound: u32) -> u32 {
	threshold := u32((u64(1) << 32) % u64(bound))
	for {
		state.random_state = u32((u64(state.random_state) * 1664525 + 1013904223) % 4294967296)
		raw := state.random_state
		if raw >= threshold do return raw % bound
	}
	return 0
}

make_node :: proc(state: ^State, key: i64, left: int, right: int) -> int {
	node := state.used
	state.used += 1
	state.nodes[node] = Node{key = key, left = left, right = right, size = 1}
	refresh(state, node)
	return node
}

split_tree :: proc(state: ^State, root: int, pivot: i64) -> (int, int) {
	if root < 0 do return -1, -1
	if state.nodes[root].key < pivot {
		low, high := split_tree(state, state.nodes[root].right, pivot)
		state.nodes[root].right = low
		refresh(state, root)
		return root, high
	}
	low, high := split_tree(state, state.nodes[root].left, pivot)
	state.nodes[root].left = high
	refresh(state, root)
	return low, root
}

join_trees :: proc(state: ^State, left: int, right: int) -> int {
	if left < 0 do return right
	if right < 0 do return left
	left_size := u32(tree_size(state, left))
	total := left_size + u32(tree_size(state, right))
	if randbelow(state, total) < left_size {
		state.nodes[left].right = join_trees(state, state.nodes[left].right, right)
		refresh(state, left)
		return left
	}
	state.nodes[right].left = join_trees(state, left, state.nodes[right].left)
	refresh(state, right)
	return right
}

contains :: proc(state: ^State, root_input: int, key: i64) -> bool {
	root := root_input
	for root >= 0 {
		if key == state.nodes[root].key do return true
		if key < state.nodes[root].key do root = state.nodes[root].left
		else do root = state.nodes[root].right
	}
	return false
}

insert_absent :: proc(state: ^State, root: int, key: i64) -> int {
	if root < 0 do return make_node(state, key, -1, -1)
	if randbelow(state, u32(tree_size(state, root) + 1)) == 0 {
		left, right := split_tree(state, root, key)
		return make_node(state, key, left, right)
	}
	if key < state.nodes[root].key do state.nodes[root].left = insert_absent(state, state.nodes[root].left, key)
	else do state.nodes[root].right = insert_absent(state, state.nodes[root].right, key)
	refresh(state, root)
	return root
}

erase_key :: proc(state: ^State, root: int, key: i64) -> int {
	if root < 0 do return -1
	if key == state.nodes[root].key do return join_trees(state, state.nodes[root].left, state.nodes[root].right)
	if key < state.nodes[root].key do state.nodes[root].left = erase_key(state, state.nodes[root].left, key)
	else do state.nodes[root].right = erase_key(state, state.nodes[root].right, key)
	refresh(state, root)
	return root
}

kth :: proc(state: ^State, root_input: int, rank_input: int) -> i64 {
	if rank_input > tree_size(state, root_input) do return -1
	root, rank := root_input, rank_input
	for root >= 0 {
		left_size := tree_size(state, state.nodes[root].left)
		if rank == left_size + 1 do return state.nodes[root].key
		if rank <= left_size do root = state.nodes[root].left
		else { rank -= left_size + 1; root = state.nodes[root].right }
	}
	return -1
}

minimum :: proc(state: ^State, root_input: int) -> i64 {
	if root_input < 0 do return -1
	root := root_input
	for state.nodes[root].left >= 0 do root = state.nodes[root].left
	return state.nodes[root].key
}

maximum :: proc(state: ^State, root_input: int) -> i64 {
	if root_input < 0 do return -1
	root := root_input
	for state.nodes[root].right >= 0 do root = state.nodes[root].right
	return state.nodes[root].key
}

valid_operation :: proc(input: [^]i64, offset: c.size_t) -> bool {
	op, a, b, c_value := input[offset], input[offset + 1], input[offset + 2], input[offset + 3]
	if op == 0 || op == 1 do return (a == 0 || a == 1) && b >= 0 && b <= 1000 && c_value == 0
	if op == 2 do return (a == 0 || a == 1) && b >= 1 && b <= 65 && c_value == 0
	if op == 3 do return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c_value >= 0 && c_value <= 1001
	if op == 4 do return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c_value == 0
	return false
}

@(export)
randomized_binary_search_tree_order_statistics_split_join :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 164 do return -1
	n, q, seed := input[0], input[1], input[2]
	if n < 0 || n > 32 || q < 0 || q > 32 || seed < 0 || seed > 4294967295 do return -1
	if length != c.size_t(3 + n + 4 * q) do return -1
	for i := c.size_t(0); i < c.size_t(n); i += 1 {
		if input[3 + i] < 0 || input[3 + i] > 1000 || (i > 0 && input[2 + i] >= input[3 + i]) do return -1
	}
	start := c.size_t(3 + n)
	for op := c.size_t(0); op < c.size_t(q); op += 1 {
		if !valid_operation(input, start + 4 * op) do return -1
	}

	state := State{random_state = u32(seed)}
	roots := [2]int{-1, -1}
	for i := c.size_t(0); i < c.size_t(n); i += 1 { roots[0] = insert_absent(&state, roots[0], input[3 + i]) }
	checksum, query_number := i64(0), i64(0)
	for op := c.size_t(0); op < c.size_t(q); op += 1 {
		offset := start + 4 * op
		code := input[offset]
		tree := int(input[offset + 1])
		arg, extra := input[offset + 2], input[offset + 3]
		if code == 0 {
			if !contains(&state, roots[tree], arg) do roots[tree] = insert_absent(&state, roots[tree], arg)
		} else if code == 1 { roots[tree] = erase_key(&state, roots[tree], arg) }
		else if code == 2 { query_number += 1; checksum += query_number * (kth(&state, roots[tree], int(arg)) + 1) }
		else if code == 3 {
			destination := int(arg)
			if roots[destination] >= 0 do return -1
			low, high := split_tree(&state, roots[tree], extra)
			roots[tree], roots[destination] = low, high
		} else {
			right := int(arg)
			left_max, right_min := maximum(&state, roots[tree]), minimum(&state, roots[right])
			if left_max >= 0 && right_min >= 0 && left_max >= right_min do return -1
			roots[tree] = join_trees(&state, roots[tree], roots[right])
			roots[right] = -1
		}
	}
	return checksum
}
