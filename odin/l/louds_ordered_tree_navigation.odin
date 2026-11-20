package louds_ordered_tree_navigation

import "core:c"

MAX_NODES :: 32
MAX_QUERIES :: 32
MAX_INPUT_WORDS :: 130
MAX_OUTPUT_WORDS :: 4 + MAX_QUERIES

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
louds_ordered_tree_navigation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_WORDS do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_NODES || q_value < 0 || q_value > MAX_QUERIES do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2 + n - 1 + 3 * q) do return -1

	parent: [MAX_NODES]int
	for vertex := 1; vertex < n; vertex += 1 {
		value := input[1 + vertex]
		if value < 0 || value >= i64(vertex) do return -1
		parent[vertex] = int(value)
	}
	query_base := n + 1
	for index := 0; index < q; index += 1 {
		offset := query_base + 3 * index
		opcode, node, argument := input[offset], input[offset + 1], input[offset + 2]
		if node < 0 || node >= n_value do return -1
		if opcode == 0 || opcode == 1 {
			if argument != 0 do return -1
		} else if opcode == 2 {
			if argument < 0 || argument > n_value do return -1
		} else do return -1
	}

	order: [MAX_NODES]int
	order_count, cursor := 1, 0
	for cursor < order_count {
		vertex := order[cursor]
		for child := 1; child < n; child += 1 {
			if parent[child] == vertex {
				order[order_count] = child
				order_count += 1
			}
		}
		cursor += 1
	}
	if order_count != n do return -1

	degree: [MAX_NODES]int
	for node := 0; node < n; node += 1 {
		for child := 1; child < n; child += 1 {
			if parent[child] == order[node] do degree[node] += 1
		}
	}

	packed: u64 = 0
	bit_length := 0
	for node := 0; node < n; node += 1 {
		for child := 0; child < degree[node]; child += 1 {
			packed |= u64(1) << u64(bit_length)
			bit_length += 1
		}
		bit_length += 1
	}

	decoded: [MAX_NODES]int
	rank_prefix: [MAX_NODES + 1]int
	bit_position, previous_zero := 0, -1
	for node := 0; node < n; node += 1 {
		for bit_position < bit_length && ((packed >> u64(bit_position)) & 1) != 0 {
			bit_position += 1
		}
		decoded[node] = bit_position - previous_zero - 1
		previous_zero = bit_position
		bit_position += 1
		rank_prefix[node + 1] = rank_prefix[node] + decoded[node]
	}

	words: [MAX_OUTPUT_WORDS]i64
	words[0], words[1], words[2], words[3] = n_value, i64(bit_length), i64(packed), q_value
	for index := 0; index < q; index += 1 {
		offset := query_base + 3 * index
		opcode := input[offset]
		node := int(input[offset + 1])
		argument := input[offset + 2]
		answer: i64 = -1
		if opcode == 0 {
			answer = i64(decoded[node])
		} else if opcode == 1 {
			if node != 0 {
				for candidate := 0; candidate < n; candidate += 1 {
					if rank_prefix[candidate + 1] >= node {
						answer = i64(candidate)
						break
					}
				}
			}
		} else if int(argument) < decoded[node] {
			answer = i64(1 + rank_prefix[node] + int(argument))
		}
		words[4 + index] = answer
	}
	required := 8 * (4 + q)
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < 4 + q; index += 1 {
		store_i64_le(output, 8 * index, words[index])
	}
	return i64(required)
}
