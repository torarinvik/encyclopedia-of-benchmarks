package suffix_tree

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_NODES :: 1 + 2 * MAX_TEXT_LENGTH
MAX_EDGES :: 2 * MAX_TEXT_LENGTH
MAX_OUTPUT_BYTES :: 5176

append_edge :: proc(parent, child: int, first_edge, last_edge: ^[MAX_NODES]int,
			edge_child, edge_next: ^[MAX_EDGES]int, edge_count: ^int) {
	edge := edge_count^
	edge_count^ += 1
	edge_child[edge] = child
	edge_next[edge] = -1
	if last_edge[parent] < 0 {
		first_edge[parent] = edge
	} else {
		edge_next[last_edge[parent]] = edge
	}
	last_edge[parent] = edge
}

write_u64 :: proc(output: ^[MAX_OUTPUT_BYTES]u8, position: ^int, value: u64) {
	for shift := 0; shift < 8; shift += 1 {
		output[position^] = u8((value >> (shift * 8)) & 0xff)
		position^ += 1
	}
}

@(export)
suffix_tree_construct :: proc "c" (input: [^]i64, input_length: c.size_t,
			output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > 66 do return -1
	text_length_value := input[0]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
	text_length := int(text_length_value)
	if int(input_length) != 1+text_length do return -1
	text: [MAX_TEXT_LENGTH]u8
	for i := 0; i < text_length; i += 1 {
		code := input[1+i]
		if code < 0 || code > 127 do return -1
		text[i] = u8(code)
	}

	labels: [MAX_NODES][MAX_TEXT_LENGTH]u8
	label_lengths: [MAX_NODES]int
	first_edge: [MAX_NODES]int
	last_edge: [MAX_NODES]int
	edge_child: [MAX_EDGES]int
	edge_next: [MAX_EDGES]int
	for i := 0; i < MAX_NODES; i += 1 {
		first_edge[i] = -1
		last_edge[i] = -1
	}
	for i := 0; i < MAX_EDGES; i += 1 { edge_next[i] = -1 }
	node_count := 1
	edge_count := 0

	for start := 0; start < text_length; start += 1 {
		suffix_length := text_length-start
		offset := 0
		node := 0
		for offset < suffix_length {
			first_code := text[start+offset]
			selected := first_edge[node]
			for selected >= 0 && labels[edge_child[selected]][0] != first_code {
				selected = edge_next[selected]
			}
			if selected < 0 {
				leaf := node_count
				node_count += 1
				leaf_length := suffix_length-offset
				for i := 0; i < leaf_length; i += 1 { labels[leaf][i] = text[start+offset+i] }
				label_lengths[leaf] = leaf_length
				append_edge(node, leaf, &first_edge, &last_edge, &edge_child, &edge_next, &edge_count)
				break
			}

			child := edge_child[selected]
			child_length := label_lengths[child]
			common := 0
			for common < child_length && offset+common < suffix_length &&
				labels[child][common] == text[start+offset+common] {
				common += 1
			}
			if common == child_length {
				offset += common
				node = child
				continue
			}

			split := node_count
			node_count += 1
			for i := 0; i < common; i += 1 { labels[split][i] = labels[child][i] }
			label_lengths[split] = common
			remainder_length := child_length-common
			for i := 0; i < remainder_length; i += 1 { labels[child][i] = labels[child][common+i] }
			label_lengths[child] = remainder_length
			edge_child[selected] = split
			append_edge(split, child, &first_edge, &last_edge, &edge_child, &edge_next, &edge_count)
			offset += common
			node = split
		}
	}

	bytes: [MAX_OUTPUT_BYTES]u8
	written := 0
	write_u64(&bytes, &written, u64(node_count))
	for node := 0; node < node_count; node += 1 {
		label_length := label_lengths[node]
		write_u64(&bytes, &written, u64(label_length))
		for i := 0; i < label_length; i += 1 {
			bytes[written] = labels[node][i]
			written += 1
		}
		child_count: u64 = 0
		edge := first_edge[node]
		for edge >= 0 {
			child_count += 1
			edge = edge_next[edge]
		}
		write_u64(&bytes, &written, child_count)
		edge = first_edge[node]
		for edge >= 0 {
			write_u64(&bytes, &written, u64(edge_child[edge]))
			edge = edge_next[edge]
		}
	}
	if output == nil || int(output_capacity) < written do return -2
	for i := 0; i < written; i += 1 { output[i] = bytes[i] }
	return i64(written)
}
