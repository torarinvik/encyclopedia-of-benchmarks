package suffix_tree_from_sa_lcp

import "core:c"

MAX_TEXT :: 8
MAX_INPUT :: 10
MAX_SUFFIXES :: 9
MAX_NODES :: 17
MAX_OUTPUT_WORDS :: 86

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

symbol_at :: proc(input: [^]i64, n, position: int) -> int {
	if position == n do return 0
	return int(input[position + 1])
}

suffix_less :: proc(input: [^]i64, n, left_start, right_start: int) -> bool {
	left, right := left_start, right_start
	total := n + 1
	for left < total && right < total {
		a, b := symbol_at(input, n, left), symbol_at(input, n, right)
		if a != b do return a < b
		left += 1; right += 1
	}
	return left == total && right != total
}

record_less :: proc(records: [^]i64, left, right: int) -> bool {
	left_at, right_at := left * 5, right * 5
	if records[left_at + 3] != records[right_at + 3] do return records[left_at + 3] < records[right_at + 3]
	if records[left_at + 2] != records[right_at + 2] do return records[left_at + 2] < records[right_at + 2]
	return records[left_at + 4] < records[right_at + 4]
}

suffix_tree_from_sa_lcp :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT do return -1
	n_raw := input[0]
	if n_raw < 0 || n_raw > MAX_TEXT || length != c.size_t(n_raw + 1) do return -1
	n := int(n_raw)
	for i := 0; i < n; i += 1 { if input[i + 1] < 1 || input[i + 1] > 255 do return -1 }
	suffix_count := n + 1
	suffix_array: [MAX_SUFFIXES]int
	lcp: [MAX_SUFFIXES]int
	for i := 0; i < suffix_count; i += 1 { suffix_array[i] = i; lcp[i] = 0 }
	for i := 1; i < suffix_count; i += 1 {
		value, j := suffix_array[i], i
		for j > 0 && suffix_less(input, n, value, suffix_array[j - 1]) {
			suffix_array[j] = suffix_array[j - 1]; j -= 1
		}
		suffix_array[j] = value
	}
	for rank := 1; rank < suffix_count; rank += 1 {
		left, right, common := suffix_array[rank - 1], suffix_array[rank], 0
		for left + common < suffix_count && right + common < suffix_count
			&& symbol_at(input, n, left + common) == symbol_at(input, n, right + common) { common += 1 }
		lcp[rank] = common
	}
	parent: [MAX_NODES]int
	depth: [MAX_NODES]int
	representative: [MAX_NODES]int
	leaf: [MAX_NODES]int
	last_child: [MAX_NODES]int
	stack: [MAX_NODES]int
	node_count, stack_size := 1, 1
	parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1; last_child[0] = -1
	stack[0] = 0
	for rank := 0; rank < suffix_count; rank += 1 {
		if rank > 0 {
			common := lcp[rank]
			for stack_size > 1 && depth[stack[stack_size - 1]] > common { stack_size -= 1 }
			top := stack[stack_size - 1]
			if depth[top] < common {
				old_child := last_child[top]
				if old_child < 0 do return -1
				internal := node_count; node_count += 1
				parent[internal] = top; depth[internal] = common
				representative[internal] = representative[old_child]; leaf[internal] = -1
				last_child[internal] = old_child; parent[old_child] = internal; last_child[top] = internal
				stack[stack_size] = internal; stack_size += 1
			}
		}
		owner := stack[stack_size - 1]
		suffix_start := suffix_array[rank]
		new_leaf := node_count; node_count += 1
		parent[new_leaf] = owner; depth[new_leaf] = suffix_count - suffix_start
		representative[new_leaf] = suffix_start; leaf[new_leaf] = suffix_start
		last_child[new_leaf] = -1; last_child[owner] = new_leaf
	}
	records: [MAX_NODES][5]i64
	for node := 0; node < node_count; node += 1 {
		at := node * 5
		if node == 0 {
			records[node][0] = -1; records[node][1] = -1; records[node][2] = -1; records[node][3] = 0; records[node][4] = -1
		} else {
			p := parent[node]
			records[node][0] = i64(representative[p]); records[node][1] = i64(depth[p])
			records[node][2] = i64(representative[node]); records[node][3] = i64(depth[node]); records[node][4] = i64(leaf[node])
		}
		_ = at
	}
	for i := 1; i < node_count; i += 1 {
		value := records[i]
		j := i
		for j > 0 && (value[3] < records[j - 1][3]
			|| (value[3] == records[j - 1][3] && value[2] < records[j - 1][2])
			|| (value[3] == records[j - 1][3] && value[2] == records[j - 1][2] && value[4] < records[j - 1][4])) {
			records[j] = records[j - 1]; j -= 1
		}
		records[j] = value
	}
	staged: [MAX_OUTPUT_WORDS]i64
	staged[0] = i64(node_count)
	words := 1
	for node := 0; node < node_count; node += 1 {
		for field := 0; field < 5; field += 1 { staged[words] = records[node][field]; words += 1 }
	}
	bytes := words * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for word := 0; word < words; word += 1 { store_i64_le(output, word * 8, staged[word]) }
	return i64(bytes)
}
