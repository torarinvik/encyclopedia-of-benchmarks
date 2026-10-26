module suffix_tree_from_sa_lcp

const max_text = 8
const max_input = 10
const max_suffixes = 9
const max_nodes = 17
const max_output_words = 86

fn store_i64_le(mut output []u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn symbol_at(input &i64, n, position int) int {
	if position == n { return 0 }
	return int(input[position + 1])
}

fn suffix_less(input &i64, n, left_start, right_start int) bool {
	mut left, mut right := left_start, right_start
	total := n + 1
	for left < total && right < total {
		a, b := symbol_at(input, n, left), symbol_at(input, n, right)
		if a != b { return a < b }
		left++
		right++
	}
	return left == total && right != total
}

@[export: 'suffix_tree_from_sa_lcp']
pub fn suffix_tree_from_sa_lcp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input { return -1 }
		n_raw := input[0]
		if n_raw < 0 || n_raw > max_text || length != usize(n_raw + 1) { return -1 }
		n := int(n_raw)
		for i in 0 .. n { if input[i + 1] < 1 || input[i + 1] > 255 { return -1 } }
		suffix_count := n + 1
		mut suffix_array := [max_suffixes]int{init: 0}
		mut lcp := [max_suffixes]int{init: 0}
		for i in 0 .. suffix_count { suffix_array[i] = i }
		for i in 1 .. suffix_count {
			value := suffix_array[i]
			mut j := i
			for j > 0 && suffix_less(input, n, value, suffix_array[j - 1]) {
				suffix_array[j] = suffix_array[j - 1]
				j--
			}
			suffix_array[j] = value
		}
		for rank in 1 .. suffix_count {
			mut left, mut right, mut common := suffix_array[rank - 1], suffix_array[rank], 0
			for left + common < suffix_count && right + common < suffix_count &&
				symbol_at(input, n, left + common) == symbol_at(input, n, right + common) { common++ }
			lcp[rank] = common
		}
		mut parent := [max_nodes]int{init: 0}
		mut depth := [max_nodes]int{init: 0}
		mut representative := [max_nodes]int{init: 0}
		mut leaf := [max_nodes]int{init: 0}
		mut last_child := [max_nodes]int{init: -1}
		mut stack := [max_nodes]int{init: 0}
		mut node_count, mut stack_size := 1, 1
		parent[0] = -1
		representative[0] = -1
		leaf[0] = -1
		for rank in 0 .. suffix_count {
			if rank > 0 {
				common := lcp[rank]
				for stack_size > 1 && depth[stack[stack_size - 1]] > common { stack_size-- }
				top := stack[stack_size - 1]
				if depth[top] < common {
					old_child := last_child[top]
					if old_child < 0 { return -1 }
					internal := node_count
					node_count++
					parent[internal] = top
					depth[internal] = common
					representative[internal] = representative[old_child]
					leaf[internal] = -1
					last_child[internal] = old_child
					parent[old_child] = internal
					last_child[top] = internal
					stack[stack_size] = internal
					stack_size++
				}
			}
			owner := stack[stack_size - 1]
			suffix_start := suffix_array[rank]
			new_leaf := node_count
			node_count++
			parent[new_leaf] = owner
			depth[new_leaf] = suffix_count - suffix_start
			representative[new_leaf] = suffix_start
			leaf[new_leaf] = suffix_start
			last_child[new_leaf] = -1
			last_child[owner] = new_leaf
		}
		mut records := [max_nodes][5]i64{init: 0}
		for node in 0 .. node_count {
			if node == 0 {
				records[node][0] = -1
				records[node][1] = -1
				records[node][2] = -1
				records[node][3] = 0
				records[node][4] = -1
			} else {
				p := parent[node]
				records[node][0] = i64(representative[p])
				records[node][1] = i64(depth[p])
				records[node][2] = i64(representative[node])
				records[node][3] = i64(depth[node])
				records[node][4] = i64(leaf[node])
			}
		}
		for i in 1 .. node_count {
			value := records[i]
			mut j := i
			for j > 0 && (value[3] < records[j - 1][3] ||
				(value[3] == records[j - 1][3] && value[2] < records[j - 1][2]) ||
				(value[3] == records[j - 1][3] && value[2] == records[j - 1][2] && value[4] < records[j - 1][4])) {
				records[j] = records[j - 1]
				j--
			}
			records[j] = value
		}
		mut staged := [max_output_words]i64{init: 0}
		staged[0] = i64(node_count)
		mut words := 1
		for node in 0 .. node_count {
			for field in 0 .. 5 { staged[words] = records[node][field]; words++ }
		}
		bytes := words * 8
		if output == nil || capacity < bytes { return -2 }
		for word in 0 .. words { store_i64_le(mut output[..], word * 8, staged[word]) }
		return i64(bytes)
	}
}
