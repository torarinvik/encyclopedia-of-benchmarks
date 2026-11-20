package suffix_tray_pattern_query

import "core:c"

MAX_TEXT :: 12
MAX_PATTERN :: 8
MAX_SIGMA :: 4
MAX_SUFFIXES :: MAX_TEXT + 1
MAX_NODES :: 2 * MAX_SUFFIXES - 1
MAX_INPUT :: 24
MAX_OUTPUT :: 16

Tray_Node :: struct {
	edge_start, edge_length, depth, leaf_start: int,
	child: [5]int,
	leaf_count, sa_left, sa_right: int,
	sigma: bool,
	kind, sigma_child_count: int,
	sigma_child: [5]int,
	child_by_symbol, group_by_symbol: [MAX_SIGMA]int,
	gap_count: int,
	gap_left, gap_right: [5]int,
	separator, only_sigma_child: int,
	left_valid, right_valid: bool,
	left_interval, right_interval: [2]int,
}

init_node :: proc(node: ^Tray_Node, start, edge_length, depth, leaf: int) {
	node.edge_start = start
	node.edge_length = edge_length
	node.depth = depth
	node.leaf_start = leaf
	for i := 0; i < 5; i += 1 {
		node.child[i] = -1
		node.sigma_child[i] = -1
		node.gap_left[i] = -1
		node.gap_right[i] = -1
	}
	for i := 0; i < MAX_SIGMA; i += 1 {
		node.child_by_symbol[i] = -1
		node.group_by_symbol[i] = -1
	}
	node.leaf_count = 0
	node.sa_left = 0
	node.sa_right = -1
	node.sigma = false
	node.kind = 0
	node.sigma_child_count = 0
	node.gap_count = 0
	node.separator = -1
	node.only_sigma_child = -1
	node.left_valid = false
	node.right_valid = false
	node.left_interval = [2]int{-1, -1}
	node.right_interval = [2]int{-1, -1}
}

suffix_compare :: proc(text: [MAX_SUFFIXES]int, a, b, length: int) -> int {
	offset := 0
	for a+offset < length && b+offset < length {
		if text[a+offset] != text[b+offset] {
			if text[a+offset] < text[b+offset] do return -1
			return 1
		}
		offset += 1
	}
	if a+offset == length && b+offset == length do return 0
	if a+offset == length do return -1
	return 1
}

build_suffix_array :: proc(text: [MAX_SUFFIXES]int, length: int,
		suffixes, rank: ^[MAX_SUFFIXES]int) {
	for i := 0; i < length; i += 1 do suffixes^[i] = i
	for i := 1; i < length; i += 1 {
		item := suffixes^[i]
		j := i
		for j > 0 && suffix_compare(text, item, suffixes^[j-1], length) < 0 {
			suffixes^[j] = suffixes^[j-1]
			j -= 1
		}
		suffixes^[j] = item
	}
	for i := 0; i < length; i += 1 do rank^[suffixes^[i]] = i
}

insert_suffix :: proc(nodes: [^]Tray_Node, node_count: ^int,
		text: [MAX_SUFFIXES]int, text_length, start: int) {
	current := 0
	position := start
	for position < text_length {
		symbol := text[position]
		child_id := nodes[current].child[symbol+1]
		if child_id < 0 {
			child_id = node_count^
			node_count^ += 1
			edge_length := text_length-position
			init_node(&nodes[child_id], position, edge_length, nodes[current].depth+edge_length, start)
			nodes[current].child[symbol+1] = child_id
			return
		}
		common := 0
		for common < nodes[child_id].edge_length && position+common < text_length &&
			text[position+common] == text[nodes[child_id].edge_start+common] {
			common += 1
		}
		if common == nodes[child_id].edge_length {
			position += common
			current = child_id
			continue
		}
		split_id := node_count^
		node_count^ += 1
		old_start := nodes[child_id].edge_start
		init_node(&nodes[split_id], old_start, common, nodes[current].depth+common, -1)
		nodes[current].child[symbol+1] = split_id
		nodes[child_id].edge_start += common
		nodes[child_id].edge_length -= common
		nodes[split_id].child[text[nodes[child_id].edge_start]+1] = child_id
		new_start := position+common
		new_id := node_count^
		node_count^ += 1
		new_length := text_length-new_start
		init_node(&nodes[new_id], new_start, new_length, nodes[split_id].depth+new_length, start)
		nodes[split_id].child[text[new_start]+1] = new_id
		return
	}
}

summarize_node :: proc(nodes: [^]Tray_Node, id: int, rank: [MAX_SUFFIXES]int, sigma: int) {
	if nodes[id].leaf_start >= 0 {
		nodes[id].leaf_count = 1
		nodes[id].sa_left = rank[nodes[id].leaf_start]
		nodes[id].sa_right = nodes[id].sa_left
		return
	}
	children: [5]int
	count := 0
	for symbol := -1; symbol < sigma; symbol += 1 {
		child := nodes[id].child[symbol+1]
		if child >= 0 { children[count] = child; count += 1 }
	}
	nodes[id].leaf_count = 0
	nodes[id].sa_left = MAX_SUFFIXES
	nodes[id].sa_right = -1
	for i := 0; i < count; i += 1 {
		child := children[i]
		summarize_node(nodes, child, rank, sigma)
		nodes[id].leaf_count += nodes[child].leaf_count
		if nodes[child].sa_left < nodes[id].sa_left do nodes[id].sa_left = nodes[child].sa_left
		if nodes[child].sa_right > nodes[id].sa_right do nodes[id].sa_right = nodes[child].sa_right
	}
}

set_interval :: proc(valid: ^bool, interval: ^[2]int, nodes: [^]Tray_Node, children: [5]int, count: int) {
	if count == 0 { valid^ = false; interval^[0] = -1; interval^[1] = -1; return }
	valid^ = true
	interval^[0] = nodes[children[0]].sa_left
	interval^[1] = nodes[children[count-1]].sa_right
}

build_tray :: proc(nodes: [^]Tray_Node, node_count, sigma: int, text: [MAX_SUFFIXES]int) {
	for id := 0; id < node_count; id += 1 do nodes[id].sigma = nodes[id].leaf_count >= sigma
	for id := 0; id < node_count; id += 1 {
		if !nodes[id].sigma do continue
		children: [5]int
		child_count := 0
		for symbol := -1; symbol < sigma; symbol += 1 {
			child := nodes[id].child[symbol+1]
			if child >= 0 { children[child_count] = child; child_count += 1 }
		}
		sigma_children: [5]int
		sig_count := 0
		for i := 0; i < child_count; i += 1 {
			if nodes[children[i]].sigma { sigma_children[sig_count] = children[i]; sig_count += 1 }
		}
		nodes[id].sigma_child_count = sig_count
		for i := 0; i < sig_count; i += 1 do nodes[id].sigma_child[i] = sigma_children[i]
		if sig_count == 0 { nodes[id].kind = 3; continue }
		if sig_count == 1 {
			nodes[id].kind = 2
			child := sigma_children[0]
			nodes[id].only_sigma_child = child
			nodes[id].separator = text[nodes[child].edge_start]
			left, right: [5]int
			left_count, right_count := 0, 0
			after := false
			for i := 0; i < child_count; i += 1 {
				item := children[i]
				if item == child { after = true; continue }
				if !nodes[item].sigma {
					if after { right[right_count] = item; right_count += 1 }
					else { left[left_count] = item; left_count += 1 }
				}
			}
			set_interval(&nodes[id].left_valid, &nodes[id].left_interval, nodes, left, left_count)
			set_interval(&nodes[id].right_valid, &nodes[id].right_interval, nodes, right, right_count)
			continue
		}
		nodes[id].kind = 1
		gaps: [6][5]int
		gap_counts: [6]int
		gap := 0
		for i := 0; i < child_count; i += 1 {
			item := children[i]
			if nodes[item].sigma { gap += 1 }
			else { gaps[gap][gap_counts[gap]] = item; gap_counts[gap] += 1 }
		}
		nodes[id].gap_count = sig_count+1
		for g := 0; g <= sig_count; g += 1 {
			if gap_counts[g] > 0 {
				nodes[id].gap_left[g] = nodes[gaps[g][0]].sa_left
				nodes[id].gap_right[g] = nodes[gaps[g][gap_counts[g]-1]].sa_right
			}
		}
		for symbol := 0; symbol < sigma; symbol += 1 {
			found := -1
			preceding := 0
			for i := 0; i < sig_count; i += 1 {
				first := text[nodes[sigma_children[i]].edge_start]
				if first == symbol { found = sigma_children[i]; break }
				if first < symbol do preceding += 1
			}
			if found >= 0 do nodes[id].child_by_symbol[symbol] = found
			else if gap_counts[preceding] > 0 do nodes[id].group_by_symbol[symbol] = preceding
		}
	}
}

compare_suffix_pattern :: proc(text: [MAX_SUFFIXES]int, text_length, suffix_start: int,
		pattern: [MAX_PATTERN]int, q, start_at: int, lcp: ^int) -> int {
	i := start_at
	for i < q && suffix_start+i < text_length {
		if text[suffix_start+i] != pattern[i] { lcp^ = i; if text[suffix_start+i] < pattern[i] do return -1; return 1 }
		i += 1
	}
	lcp^ = i
	if i == q do return 1
	return -1
}

interval_search :: proc(text: [MAX_SUFFIXES]int, text_length: int, pattern: [MAX_PATTERN]int,
		q: int, suffixes: [MAX_SUFFIXES]int, lo, hi, known_prefix: int) -> int {
	low, high := lo-1, hi+1
	low_lcp, high_lcp := known_prefix, known_prefix
	for high-low > 1 {
		middle := (low+high)/2
		lcp := known_prefix
		start_at := low_lcp
		if high_lcp < start_at do start_at = high_lcp
		comparison := compare_suffix_pattern(text, text_length, suffixes[middle], pattern, q, start_at, &lcp)
		if comparison < 0 { low = middle; low_lcp = lcp }
		else { high = middle; high_lcp = lcp }
	}
	if high > hi do return -1
	start := suffixes[high]
	if start+q > text_length do return -1
	for i := 0; i < q; i += 1 { if text[start+i] != pattern[i] do return -1 }
	return start
}

tray_query :: proc(text: [MAX_SUFFIXES]int, text_length: int, pattern: [MAX_PATTERN]int,
		q, sigma: int, suffixes: [MAX_SUFFIXES]int, nodes: [^]Tray_Node) -> int {
	current, matched := 0, 0
	for {
		if matched == q do return suffixes[nodes[current].sa_left]
		symbol := pattern[matched]
		if !nodes[current].sigma || nodes[current].kind == 3 do return interval_search(text, text_length, pattern, q, suffixes, nodes[current].sa_left, nodes[current].sa_right, matched)
		next, interval_left, interval_right := -1, -1, -1
		if nodes[current].kind == 1 {
			if symbol < 0 || symbol >= sigma do return -1
			next = nodes[current].child_by_symbol[symbol]
			if next < 0 {
				group := nodes[current].group_by_symbol[symbol]
				if group < 0 || nodes[current].gap_left[group] < 0 do return -1
				interval_left = nodes[current].gap_left[group]
				interval_right = nodes[current].gap_right[group]
			}
		} else {
			next = nodes[current].only_sigma_child
			if symbol != nodes[current].separator {
				if symbol < nodes[current].separator {
					if !nodes[current].left_valid do return -1
					interval_left = nodes[current].left_interval[0]; interval_right = nodes[current].left_interval[1]
				} else {
					if !nodes[current].right_valid do return -1
					interval_left = nodes[current].right_interval[0]; interval_right = nodes[current].right_interval[1]
				}
			}
		}
		if interval_left >= 0 do return interval_search(text, text_length, pattern, q, suffixes, interval_left, interval_right, matched)
		if next < 0 do return -1
		representative := suffixes[nodes[next].sa_left]
		edge_position := nodes[current].depth
		for matched < q && edge_position < nodes[next].depth {
			if text[representative+edge_position] != pattern[matched] do return -1
			matched += 1; edge_position += 1
		}
		if matched == q do return suffixes[nodes[next].sa_left]
		if edge_position != nodes[next].depth do return -1
		current = next
	}
}

put_i64_le :: proc(output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for i := 0; i < 8; i += 1 { output[position+i] = u8((bits >> (8*i)) & 255) }
}

@(export)
suffix_tray_pattern_query :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	sigma_raw, n_raw, q_raw := input[0], input[1], input[2]
	if sigma_raw < 2 || sigma_raw > MAX_SIGMA || n_raw < 1 || n_raw > MAX_TEXT || q_raw < 1 || q_raw > MAX_PATTERN do return -1
	sigma, n, q := int(sigma_raw), int(n_raw), int(q_raw)
	if int(length) != 3+n+q do return -1
	text: [MAX_SUFFIXES]int
	pattern: [MAX_PATTERN]int
	for i := 0; i < n; i += 1 { if input[3+i] < 0 || input[3+i] >= sigma_raw do return -1; text[i] = int(input[3+i]) }
	text[n] = -1
	for i := 0; i < q; i += 1 { if input[3+n+i] < 0 || input[3+n+i] >= sigma_raw do return -1; pattern[i] = int(input[3+n+i]) }
	if output == nil || capacity < MAX_OUTPUT do return -2
	suffixes, rank: [MAX_SUFFIXES]int
	build_suffix_array(text, n+1, &suffixes, &rank)
	nodes: [MAX_NODES]Tray_Node
	for i := 0; i < MAX_NODES; i += 1 { init_node(&nodes[i], 0, 0, 0, -1) }
	node_count := 1
	for start := 0; start <= n; start += 1 { insert_suffix(&nodes[0], &node_count, text, n+1, start) }
	summarize_node(&nodes[0], 0, rank, sigma)
	build_tray(&nodes[0], node_count, sigma, text)
	found := tray_query(text, n+1, pattern, q, sigma, suffixes, &nodes[0])
	put_i64_le(output, 0, i64(if found < 0 { 0 } else { 1 }))
	put_i64_le(output, 8, i64(found))
	return MAX_OUTPUT
}
