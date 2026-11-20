package dfuds_ordered_tree_navigation

import "core:c"

MAX_N :: 31
MAX_Q :: 32
MAX_INPUT :: 129
MAX_BITS :: 2 * MAX_N
MAX_OUTPUT_WORDS :: 4 + MAX_Q

bit_at :: proc "contextless" (bits: u64, position: int) -> bool {
	return ((bits >> u64(position - 1)) & 1) != 0
}

find_close :: proc "contextless" (bits: u64, bit_length, start: int) -> int {
	balance := 0
	for position := start; position <= bit_length; position += 1 {
		if bit_at(bits, position) { balance += 1 } else { balance -= 1 }
		if balance == 0 { return position }
	}
	return bit_length + 1
}

find_open :: proc "contextless" (bits: u64, position: int) -> int {
	if bit_at(bits, position) { return position }
	balance := 0
	for candidate := position; candidate > 0; candidate -= 1 {
		if bit_at(bits, candidate) { balance -= 1 } else { balance += 1 }
		if balance == 0 { return candidate }
	}
	return 0
}

previous_zero :: proc "contextless" (bits: u64, position: int) -> int {
	for candidate := position; candidate > 1; candidate -= 1 {
		if !bit_at(bits, candidate - 1) { return candidate - 1 }
	}
	return 0
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
dfuds_ordered_tree_navigation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2 + n - 1 + 3 * q) do return -1

	parent: [MAX_N]int
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
		if opcode == 0 || opcode == 2 {
			if argument != 0 do return -1
		} else if opcode == 1 {
			if argument < 0 || argument > n_value do return -1
		} else do return -1
	}

	order, stack_node, next_child: [MAX_N]int
	order_count, depth := 1, 1
	for depth > 0 {
		frame := depth - 1
		node := stack_node[frame]
		child := next_child[frame]
		for child < n && parent[child] != node do child += 1
		if child < n {
			next_child[frame] = child + 1
			order[order_count] = child
			order_count += 1
			stack_node[depth] = child
			next_child[depth] = 1
			depth += 1
		} else {
			depth -= 1
		}
	}
	if order_count != n do return -1

	descriptor: [MAX_N]int
	position_to_node: [MAX_BITS + 2]int
	for position := 0; position < MAX_BITS + 2; position += 1 { position_to_node[position] = -1 }
	packed: u64 = 1
	bit_length := 1
	for node := 0; node < n; node += 1 {
		degree := 0
		for child := 1; child < n; child += 1 {
			if parent[child] == order[node] { degree += 1 }
		}
		descriptor[node] = bit_length + 1
		position_to_node[descriptor[node]] = node
		for child := 0; child < degree; child += 1 {
			packed |= u64(1) << u64(bit_length)
			bit_length += 1
		}
		bit_length += 1
	}
	if bit_length != 2 * n do return -1

	words: [MAX_OUTPUT_WORDS]i64
	words[0], words[1], words[2], words[3] = n_value, i64(bit_length), i64(packed), q_value
	for index := 0; index < q; index += 1 {
		offset := query_base + 3 * index
		opcode := input[offset]
		node := int(input[offset + 1])
		argument := input[offset + 2]
		start := descriptor[node]
		degree := 0
		for start + degree <= bit_length && bit_at(packed, start + degree) { degree += 1 }
		answer: i64 = -1
		if opcode == 0 {
			answer = i64(degree)
		} else if opcode == 1 {
			if argument < i64(degree) {
				target := start + degree - (int(argument) + 1)
				child_start := find_close(packed, bit_length, target) + 1
				if child_start > MAX_BITS + 1 || position_to_node[child_start] < 0 do return -1
				answer = i64(position_to_node[child_start])
			}
		} else if node != 0 {
			matched_open := find_open(packed, start - 1)
			parent_position := previous_zero(packed, matched_open) + 1
			if parent_position == 1 {
				answer = 0
			} else if parent_position <= MAX_BITS + 1 && position_to_node[parent_position] >= 0 {
				answer = i64(position_to_node[parent_position])
			} else do return -1
		}
		words[4 + index] = answer
	}

	required := 8 * (4 + q)
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < 4 + q; index += 1 {
		write_i64_le(output, 8 * index, words[index])
	}
	return i64(required)
}
