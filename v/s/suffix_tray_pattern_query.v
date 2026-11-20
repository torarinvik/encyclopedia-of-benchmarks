module suffix_tray_pattern_query

const max_text = 12
const max_pattern = 8
const max_sigma = 4
const max_suffixes = max_text + 1
const max_nodes = 2 * max_suffixes - 1
const max_input = 24
const max_output = 16

struct TrayNode {
	edge_start int
	edge_length int
	depth int
	leaf_start int = -1
	child [5]int
	leaf_count int
	sa_left int
	sa_right int = -1
	sigma bool
	kind int
	sigma_child_count int
	sigma_child [5]int
	child_by_symbol [max_sigma]int
	group_by_symbol [max_sigma]int
	gap_count int
	gap_left [5]int
	gap_right [5]int
	separator int = -2
	only_sigma_child int = -1
	left_interval [2]int
	right_interval [2]int
}

fn empty_node() TrayNode {
	mut node := TrayNode{}
	for i in 0 .. 5 {
		node.child[i] = -1
		node.sigma_child[i] = -1
		node.gap_left[i] = -1
		node.gap_right[i] = -1
	}
	for i in 0 .. max_sigma {
		node.child_by_symbol[i] = -1
		node.group_by_symbol[i] = -1
	}
	node.sa_right = -1
	node.separator = -2
	node.only_sigma_child = -1
	node.left_interval[0] = -1
	node.left_interval[1] = -1
	node.right_interval[0] = -1
	node.right_interval[1] = -1
	node.leaf_start = -1
	return node
}

fn slot(symbol int) int { return symbol + 1 }

fn suffix_cmp(text []int, length int, a int, b int) int {
	mut offset := 0
	for a + offset < length && b + offset < length {
		if text[a + offset] != text[b + offset] {
			return if text[a + offset] < text[b + offset] { -1 } else { 1 }
		}
		offset++
	}
	if a + offset == length && b + offset == length { return 0 }
	return if a + offset == length { -1 } else { 1 }
}

fn make_suffix_array(text []int, length int) ([]int, []int) {
	mut sa := []int{len: max_suffixes, init: 0}
	mut rank := []int{len: max_suffixes, init: 0}
	for i in 0 .. length { sa[i] = i }
	for i in 1 .. length {
		item := sa[i]
		mut j := i
		for j > 0 && suffix_cmp(text, length, item, sa[j - 1]) < 0 {
			sa[j] = sa[j - 1]
			j--
		}
		sa[j] = item
	}
	for i in 0 .. length { rank[sa[i]] = i }
	return sa, rank
}

fn insert_suffix(mut nodes []TrayNode, mut node_count int, text []int,
		text_length int, start int) {
	mut current := 0
	mut position := start
	for position < text_length {
		sym := text[position]
		child := nodes[current].child[slot(sym)]
		if child < 0 {
			id := node_count
			node_count++
			length := text_length - position
			mut leaf := empty_node()
			leaf.edge_start = position
			leaf.edge_length = length
			leaf.depth = nodes[current].depth + length
			leaf.leaf_start = start
			nodes[id] = leaf
			nodes[current].child[slot(sym)] = id
			return
		}
		mut common := 0
		for common < nodes[child].edge_length && position + common < text_length &&
			text[position + common] == text[nodes[child].edge_start + common] {
			common++
		}
		if common == nodes[child].edge_length {
			position += common
			current = child
			continue
		}
		split := node_count
		node_count++
		mut middle := empty_node()
		middle.edge_start = nodes[child].edge_start
		middle.edge_length = common
		middle.depth = nodes[current].depth + common
		nodes[split] = middle
		nodes[current].child[slot(sym)] = split
		nodes[child].edge_start += common
		nodes[child].edge_length -= common
		nodes[split].child[slot(text[nodes[child].edge_start])] = child
		new_start := position + common
		id := node_count
		node_count++
		length := text_length - new_start
		mut leaf := empty_node()
		leaf.edge_start = new_start
		leaf.edge_length = length
		leaf.depth = nodes[split].depth + length
		leaf.leaf_start = start
		nodes[id] = leaf
		nodes[split].child[slot(text[new_start])] = id
		return
	}
}

fn summarize(mut nodes []TrayNode, id int, rank []int, sigma int) {
	if nodes[id].leaf_start >= 0 {
		nodes[id].leaf_count = 1
		nodes[id].sa_left = rank[nodes[id].leaf_start]
		nodes[id].sa_right = nodes[id].sa_left
		return
	}
	mut children := []int{cap: 5}
	for symbol in -1 .. sigma {
		child := nodes[id].child[slot(symbol)]
		if child >= 0 { children << child }
	}
	mut count := 0
	mut left := max_suffixes
	mut right := -1
	for child in children {
		summarize(mut nodes, child, rank, sigma)
		count += nodes[child].leaf_count
		if nodes[child].sa_left < left { left = nodes[child].sa_left }
		if nodes[child].sa_right > right { right = nodes[child].sa_right }
	}
	nodes[id].leaf_count = count
	nodes[id].sa_left = left
	nodes[id].sa_right = right
}

fn build_tray(mut nodes []TrayNode, node_count int, sigma int, text []int) {
	for i in 0 .. node_count { nodes[i].sigma = nodes[i].leaf_count >= sigma }
	for id in 0 .. node_count {
		if !nodes[id].sigma { continue }
		mut children := []int{cap: 5}
		for symbol in -1 .. sigma {
			child := nodes[id].child[slot(symbol)]
			if child >= 0 { children << child }
		}
		mut sig := []int{cap: 5}
		for child in children { if nodes[child].sigma { sig << child } }
		nodes[id].sigma_child_count = sig.len
		for i, child in sig { nodes[id].sigma_child[i] = child }
		if sig.len == 0 { nodes[id].kind = 3; continue }
		if sig.len == 1 {
			nodes[id].kind = 2
			child := sig[0]
			nodes[id].only_sigma_child = child
			nodes[id].separator = text[nodes[child].edge_start]
			mut left := []int{cap: 5}
			mut right := []int{cap: 5}
			mut after := false
			for item in children {
				if item == child { after = true; continue }
				if !nodes[item].sigma {
					if after { right << item } else { left << item }
				}
			}
			if left.len > 0 {
				nodes[id].left_interval = [nodes[left[0]].sa_left, nodes[left[left.len - 1]].sa_right]!
			}
			if right.len > 0 {
				nodes[id].right_interval = [nodes[right[0]].sa_left, nodes[right[right.len - 1]].sa_right]!
			}
			continue
		}
		nodes[id].kind = 1
		mut groups := [6][]int{init: []int{cap: 5}}
		mut gap := 0
		for item in children {
			if nodes[item].sigma { gap++ } else { groups[gap] << item }
		}
		nodes[id].gap_count = sig.len + 1
		for g in 0 .. sig.len + 1 {
			if groups[g].len > 0 {
				nodes[id].gap_left[g] = nodes[groups[g][0]].sa_left
				nodes[id].gap_right[g] = nodes[groups[g][groups[g].len - 1]].sa_right
			}
		}
		for symbol in 0 .. sigma {
			mut exact := -1
			mut preceding := 0
			for child in sig {
				first := text[nodes[child].edge_start]
				if first == symbol { exact = child; break }
				if first < symbol { preceding++ }
			}
			if exact >= 0 { nodes[id].child_by_symbol[symbol] = exact }
			else if groups[preceding].len > 0 { nodes[id].group_by_symbol[symbol] = preceding }
		}
	}
}

fn compare_pattern(text []int, text_length int, suffix int, pattern []int,
		q int, from int) (int, int) {
	mut i := from
	for i < q && suffix + i < text_length {
		if text[suffix + i] != pattern[i] {
			return if text[suffix + i] < pattern[i] { -1 } else { 1 }, i
		}
		i++
	}
	return if i == q { 1, i } else { -1, i }
}

fn interval_search(text []int, text_length int, pattern []int, q int,
		sa []int, lo int, hi int, known int) int {
	mut low := lo - 1
	mut high := hi + 1
	mut low_lcp := known
	mut high_lcp := known
	for high - low > 1 {
		middle := (low + high) / 2
		comparison, lcp := compare_pattern(text, text_length, sa[middle], pattern, q, min(low_lcp, high_lcp))
		if comparison < 0 { low = middle; low_lcp = lcp } else { high = middle; high_lcp = lcp }
	}
	if high > hi { return -1 }
	start := sa[high]
	if start + q > text_length { return -1 }
	for i in 0 .. q { if text[start + i] != pattern[i] { return -1 } }
	return start
}

fn tray_query(text []int, text_length int, pattern []int, q int, sigma int,
		sa []int, nodes []TrayNode) int {
	mut current := 0
	mut matched := 0
	for {
		node := nodes[current]
		if matched == q { return sa[node.sa_left] }
		if !node.sigma || node.kind == 3 {
			return interval_search(text, text_length, pattern, q, sa, node.sa_left, node.sa_right, matched)
		}
		symbol := pattern[matched]
		mut next := -1
		mut lo := -1
		mut hi := -1
		if node.kind == 1 {
			next = node.child_by_symbol[symbol]
			if next < 0 {
				group := node.group_by_symbol[symbol]
				if group < 0 || node.gap_left[group] < 0 { return -1 }
				lo, hi = node.gap_left[group], node.gap_right[group]
			}
		} else {
			next = node.only_sigma_child
			if symbol != node.separator {
				if symbol < node.separator {
					if node.left_interval[0] < 0 { return -1 }
					lo, hi = node.left_interval[0], node.left_interval[1]
				} else {
					if node.right_interval[0] < 0 { return -1 }
					lo, hi = node.right_interval[0], node.right_interval[1]
				}
			}
		}
		if lo >= 0 { return interval_search(text, text_length, pattern, q, sa, lo, hi, matched) }
		if next < 0 { return -1 }
		child := nodes[next]
		representative := sa[child.sa_left]
		mut edge_position := node.depth
		for matched < q && edge_position < child.depth {
			if text[representative + edge_position] != pattern[matched] { return -1 }
			matched++
			edge_position++
		}
		if matched == q { return sa[child.sa_left] }
		if edge_position != child.depth { return -1 }
		current = next
	}
}

fn put_i64(output &u8, position int, value i64) {
	unsafe {
		bits := u64(value)
		for i in 0 .. 8 { output[position + i] = u8((bits >> (8 * i)) & 255) }
	}
}

@[export: 'suffix_tray_pattern_query']
pub fn suffix_tray_pattern_query(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		sigma64, n64, q64 := input[0], input[1], input[2]
		if sigma64 < 2 || sigma64 > max_sigma || n64 < 1 || n64 > max_text || q64 < 1 || q64 > max_pattern { return -1 }
		sigma, n, q := int(sigma64), int(n64), int(q64)
		if length != usize(3 + n + q) { return -1 }
		mut text := []int{len: max_suffixes, init: -1}
		mut pattern := []int{len: max_pattern, init: 0}
		for i in 0 .. n {
			value := input[3 + i]
			if value < 0 || value >= sigma64 { return -1 }
			text[i] = int(value)
		}
		for i in 0 .. q {
			value := input[3 + n + i]
			if value < 0 || value >= sigma64 { return -1 }
			pattern[i] = int(value)
		}
		if output == nil || capacity < max_output { return -2 }
		mut sa, rank := make_suffix_array(text, n + 1)
		mut nodes := []TrayNode{len: max_nodes}
		for i in 0 .. max_nodes { nodes[i] = empty_node() }
		mut node_count := 1
		for start in 0 .. n + 1 { insert_suffix(mut nodes, mut node_count, text, n + 1, start) }
		summarize(mut nodes, 0, rank, sigma)
		build_tray(mut nodes, node_count, sigma, text)
		found := tray_query(text, n + 1, pattern, q, sigma, sa, nodes)
		put_i64(output, 0, if found < 0 { 0 } else { 1 })
		put_i64(output, 8, found)
		return max_output
	}
}
