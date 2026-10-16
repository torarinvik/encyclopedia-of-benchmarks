package autocomplete_using_trie

import "core:c"

MAX_WORDS :: 32
MAX_LEN :: 16
MAX_QUERIES :: 16
MAX_NODES :: 513
MAX_OUTPUT_WORDS :: 8721

Node :: struct {
	child: [26]int,
	terminal: bool,
}

collect :: proc "contextless" (nodes: [^]Node, node: int, path: ^[MAX_LEN]int,
		depth: int, values: [^]i64, used: ^int, count: ^int) {
	if nodes[node].terminal {
		values[used^] = i64(depth)
		used^ += 1
		for index := 0; index < depth; index += 1 {
			values[used^] = i64(97 + path[index])
			used^ += 1
		}
		count^ += 1
	}
	for character := 0; character < 26; character += 1 {
		child := nodes[node].child[character]
		if child >= 0 {
			path[depth] = character
			collect(nodes, child, path, depth+1, values, used, count)
		}
	}
}

put_i64 :: proc "contextless" (output: [^]u8, index: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte: c.size_t = 0; byte < 8; byte += 1 {
		output[index*8+byte] = u8(bits >> (8 * byte))
	}
}

@(export)
autocomplete_using_trie :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	nodes: [MAX_NODES]Node
	query_positions: [MAX_QUERIES]c.size_t
	query_lengths: [MAX_QUERIES]c.size_t
	values: [MAX_OUTPUT_WORDS]i64

	if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_WORDS {
		return -1
	}
	for node := 0; node < MAX_NODES; node += 1 {
		for character := 0; character < 26; character += 1 {
			nodes[node].child[character] = -1
		}
	}
	node_count := 1
	position: c.size_t = 1
	for word := 0; word < int(input[0]); word += 1 {
		if position >= length {
			return -1
		}
		word_length := input[position]
		position += 1
		if word_length < 1 || word_length > MAX_LEN || position+c.size_t(word_length) > length {
			return -1
		}
		node := 0
		for index := 0; index < int(word_length); index += 1 {
			character := input[position]
			position += 1
			if character < 97 || character > 122 {
				return -1
			}
			child_index := int(character - 97)
			if nodes[node].child[child_index] < 0 {
				if node_count >= MAX_NODES {
					return -1
				}
				for child := 0; child < 26; child += 1 {
					nodes[node_count].child[child] = -1
				}
				nodes[node].child[child_index] = node_count
				node_count += 1
			}
			node = nodes[node].child[child_index]
		}
		nodes[node].terminal = true
	}

	if position >= length {
		return -1
	}
	query_count_value := input[position]
	position += 1
	if query_count_value < 0 || query_count_value > MAX_QUERIES {
		return -1
	}
	query_count := int(query_count_value)
	for query := 0; query < query_count; query += 1 {
		if position >= length {
			return -1
		}
		prefix_length := input[position]
		position += 1
		if prefix_length < 0 || prefix_length > MAX_LEN || position+c.size_t(prefix_length) > length {
			return -1
		}
		query_positions[query] = position
		query_lengths[query] = c.size_t(prefix_length)
		for index: c.size_t = 0; index < query_lengths[query]; index += 1 {
			character := input[position+index]
			if character < 97 || character > 122 {
				return -1
			}
		}
		position += query_lengths[query]
	}
	if position != length {
		return -1
	}

	used := 1
	values[0] = i64(query_count)
	for query := 0; query < query_count; query += 1 {
		node := 0
		path: [MAX_LEN]int
		found := true
		for index: c.size_t = 0; index < query_lengths[query]; index += 1 {
			child_index := int(input[query_positions[query]+index] - 97)
			path[index] = child_index
			child := nodes[node].child[child_index]
			if child < 0 {
				found = false
				break
			}
			node = child
		}
		count_position := used
		used += 1
		count := 0
		if found {
			collect(&nodes[0], node, &path, int(query_lengths[query]), &values[0], &used, &count)
		}
		values[count_position] = i64(count)
	}

	required := c.size_t(used * 8)
	if output == nil || capacity < required {
		return -2
	}
	for index: c.size_t = 0; index < c.size_t(used); index += 1 {
		put_i64(output, index, values[index])
	}
	return i64(required)
}
