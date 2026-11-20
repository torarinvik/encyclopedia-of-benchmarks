module rolling_hash_on_segment_tree_trace

const (
	max_n = 20
	max_q = 20
	max_parseable_input_length = 123
	tree_base = 32
	tree_size = 2 * tree_base
	base = i64(911382323)
	modulus = i64(1_000_000_007)
)

struct HashNode {
	hash i64
	length int
}

fn combine(left HashNode, right HashNode, powers &[max_n + 1]i64) HashNode {
	return HashNode{
		hash: (left.hash * powers[right.length] + right.hash) % modulus
		length: left.length + right.length
	}
}

fn range_hash(tree &[tree_size]HashNode, powers &[max_n + 1]i64, left int, right int) HashNode {
	mut left_index := tree_base + left
	mut right_index := tree_base + right
	mut left_result := HashNode{}
	mut right_result := HashNode{}
	for left_index < right_index {
		if left_index % 2 == 1 {
			left_result = combine(left_result, tree[left_index], powers)
			left_index++
		}
		if right_index % 2 == 1 {
			right_index--
			right_result = combine(tree[right_index], right_result, powers)
		}
		left_index /= 2
		right_index /= 2
	}
	return combine(left_result, right_result, powers)
}

fn set_symbol(mut tree [tree_size]HashNode, powers &[max_n + 1]i64, index int, symbol i64) {
	mut node := tree_base + index
	tree[node] = HashNode{hash: symbol, length: 1}
	node /= 2
	for node > 0 {
		tree[node] = combine(tree[2 * node], tree[2 * node + 1], powers)
		node /= 2
	}
}

@[export: 'rolling_hash_on_segment_tree_trace']
pub fn rolling_hash_on_segment_tree_trace(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable_input_length { return -1 }
	unsafe {
		n_word, q_word := input[0], input[1]
		if n_word < 0 || n_word > max_n || q_word < 0 || q_word > max_q { return -1 }
		n, q := int(n_word), int(q_word)
		if length != usize(2 + n + 5 * q) { return -1 }
		query_start := 2 + n
		for index in 0 .. n {
			if input[2 + index] < 0 || input[2 + index] > 25 { return -1 }
		}

		mut powers := [max_n + 1]i64{}
		powers[0] = 1
		for exponent in 1 .. max_n + 1 { powers[exponent] = powers[exponent - 1] * base % modulus }
		mut tree := [tree_size]HashNode{}
		for index in 0 .. n { tree[tree_base + index] = HashNode{hash: input[2 + index], length: 1} }
		for node in 1 .. tree_base {
			parent := tree_base - node
			tree[parent] = combine(tree[2 * parent], tree[2 * parent + 1], &powers)
		}

		mut score := i64(0)
		for operation in 0 .. q {
			offset := query_start + 5 * operation
			opcode := input[offset]
			a, b, c, d := input[offset + 1], input[offset + 2], input[offset + 3], input[offset + 4]
			mut response := i64(0)
			if opcode == 0 {
				if a < 0 || a >= n_word || b < 0 || b > 25 || c != 0 || d != 0 { return -1 }
				set_symbol(mut tree, &powers, int(a), b)
			} else if opcode == 1 {
				if a < 0 || a > b || b > n_word || c < 0 || c > d || d > n_word { return -1 }
				if b - a == d - c {
					first := range_hash(&tree, &powers, int(a), int(b))
					second := range_hash(&tree, &powers, int(c), int(d))
					if first.hash == second.hash { response = 1 }
				}
			} else { return -1 }
			score += i64(operation + 1) * (opcode * 2 + response + 1)
		}
		return score
	}
}
