package rolling_hash_on_segment_tree_trace

import "core:c"

MAX_N :: 20
MAX_Q :: 20
MAX_PARSEABLE_INPUT_LENGTH :: 123
TREE_BASE :: 32
TREE_SIZE :: 2 * TREE_BASE
BASE :: i64(911382323)
MODULUS :: i64(1_000_000_007)

Hash_Node :: struct {
	hash: i64,
	length: int,
}

combine :: proc "contextless" (left, right: Hash_Node, powers: [^]i64) -> Hash_Node {
	return Hash_Node{hash = (left.hash * powers[right.length] + right.hash) % MODULUS,
		length = left.length + right.length}
}

range_hash :: proc "contextless" (tree: [^]Hash_Node, powers: [^]i64,
	left, right: int) -> Hash_Node {
	mut left_index := TREE_BASE + left
	mut right_index := TREE_BASE + right
	mut left_result := Hash_Node{}
	mut right_result := Hash_Node{}
	for left_index < right_index {
		if left_index % 2 == 1 {
			left_result = combine(left_result, tree[left_index], powers)
			left_index += 1
		}
		if right_index % 2 == 1 {
			right_index -= 1
			right_result = combine(tree[right_index], right_result, powers)
		}
		left_index /= 2
		right_index /= 2
	}
	return combine(left_result, right_result, powers)
}

set_symbol :: proc "contextless" (tree: [^]Hash_Node, powers: [^]i64,
	index: int, symbol: i64) {
	mut node := TREE_BASE + index
	tree[node] = Hash_Node{hash = symbol, length = 1}
	node /= 2
	for node > 0 {
		tree[node] = combine(tree[2*node], tree[2*node+1], powers)
		node /= 2
	}
}

@(export)
rolling_hash_on_segment_tree_trace :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	n_word, q_word := input[0], input[1]
	if n_word < 0 || n_word > MAX_N || q_word < 0 || q_word > MAX_Q do return -1
	n, q := int(n_word), int(q_word)
	if int(length) != 2+n+5*q do return -1
	query_start := 2+n
	for index := 0; index < n; index += 1 {
		if input[2+index] < 0 || input[2+index] > 25 do return -1
	}

	powers: [MAX_N+1]i64
	powers[0] = 1
	for exponent := 1; exponent <= MAX_N; exponent += 1 {
		powers[exponent] = powers[exponent-1] * BASE % MODULUS
	}
	tree: [TREE_SIZE]Hash_Node
	for index := 0; index < n; index += 1 {
		tree[TREE_BASE+index] = Hash_Node{hash = input[2+index], length = 1}
	}
	for node := TREE_BASE-1; node > 0; node -= 1 {
		tree[node] = combine(tree[2*node], tree[2*node+1], &powers[0])
	}

	mut score := i64(0)
	for operation := 0; operation < q; operation += 1 {
		offset := query_start+5*operation
		opcode := input[offset]
		a, b, c, d := input[offset+1], input[offset+2], input[offset+3], input[offset+4]
		response := i64(0)
		if opcode == 0 {
			if a < 0 || a >= n_word || b < 0 || b > 25 || c != 0 || d != 0 do return -1
			set_symbol(&tree[0], &powers[0], int(a), b)
		} else if opcode == 1 {
			if a < 0 || a > b || b > n_word || c < 0 || c > d || d > n_word do return -1
			if b-a == d-c {
				first := range_hash(&tree[0], &powers[0], int(a), int(b))
				second := range_hash(&tree[0], &powers[0], int(c), int(d))
				if first.hash == second.hash do response = 1
			}
		} else do return -1
		score += i64(operation+1) * (opcode*2 + response + 1)
	}
	return score
}
