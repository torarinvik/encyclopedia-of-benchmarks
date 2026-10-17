module suffix_tree

const max_text_length = 64
const max_nodes = 1 + 2 * max_text_length
const max_edges = 2 * max_text_length
const max_output_bytes = 5176

fn write_u64(mut buffer []u8, mut position int, value u64) {
	for shift in 0 .. 8 {
		buffer[position] = u8((value >> (shift * 8)) & 0xff)
		position++
	}
}

@[export: 'suffix_tree_construct']
pub fn suffix_tree_construct(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 66 { return -1 }
		text_length_value := input[0]
		if text_length_value < 0 || text_length_value > i64(max_text_length) { return -1 }
		text_length := int(text_length_value)
		if input_length != usize(1 + text_length) { return -1 }
		mut text := [max_text_length]u8{}
		for i in 0 .. text_length {
			code := input[1 + i]
			if code < 0 || code > 127 { return -1 }
			text[i] = u8(code)
		}

		mut labels := [max_nodes][max_text_length]u8{}
		mut label_lengths := [max_nodes]int{}
		mut first_edge := [max_nodes]int{}
		mut last_edge := [max_nodes]int{}
		mut edge_child := [max_edges]int{}
		mut edge_next := [max_edges]int{}
		for i in 0 .. max_nodes {
			first_edge[i] = -1
			last_edge[i] = -1
		}
		for i in 0 .. max_edges { edge_next[i] = -1 }
		mut node_count := 1
		mut edge_count := 0

		for start in 0 .. text_length {
			suffix_length := text_length - start
			mut offset := 0
			mut node := 0
			for offset < suffix_length {
				first_code := text[start + offset]
				mut selected := first_edge[node]
				for selected >= 0 && labels[edge_child[selected]][0] != first_code {
					selected = edge_next[selected]
				}
				if selected < 0 {
					leaf := node_count
					node_count++
					leaf_length := suffix_length - offset
					for i in 0 .. leaf_length { labels[leaf][i] = text[start + offset + i] }
					label_lengths[leaf] = leaf_length
					edge := edge_count
					edge_count++
					edge_child[edge] = leaf
					edge_next[edge] = -1
					if last_edge[node] < 0 {
						first_edge[node] = edge
					} else {
						edge_next[last_edge[node]] = edge
					}
					last_edge[node] = edge
					break
				}

				child := edge_child[selected]
				child_length := label_lengths[child]
				mut common := 0
				for common < child_length && offset + common < suffix_length &&
					labels[child][common] == text[start + offset + common] {
					common++
				}
				if common == child_length {
					offset += common
					node = child
					continue
				}

				split := node_count
				node_count++
				for i in 0 .. common { labels[split][i] = labels[child][i] }
				label_lengths[split] = common
				remainder_length := child_length - common
				for i in 0 .. remainder_length { labels[child][i] = labels[child][common + i] }
				label_lengths[child] = remainder_length
				edge_child[selected] = split
				edge := edge_count
				edge_count++
				edge_child[edge] = child
				edge_next[edge] = -1
				first_edge[split] = edge
				last_edge[split] = edge
				offset += common
				node = split
			}
		}

		mut bytes := [max_output_bytes]u8{}
		mut written := 0
		write_u64(mut bytes, mut written, u64(node_count))
		for node in 0 .. node_count {
			label_length := label_lengths[node]
			write_u64(mut bytes, mut written, u64(label_length))
			for i in 0 .. label_length {
				bytes[written] = labels[node][i]
				written++
			}
			mut child_count := u64(0)
			mut edge := first_edge[node]
			for edge >= 0 {
				child_count++
				edge = edge_next[edge]
			}
			write_u64(mut bytes, mut written, child_count)
			edge = first_edge[node]
			for edge >= 0 {
				write_u64(mut bytes, mut written, u64(edge_child[edge]))
				edge = edge_next[edge]
			}
		}
		if output == nil || output_capacity < usize(written) { return -2 }
		for i in 0 .. written { output[i] = bytes[i] }
		return i64(written)
	}
}
