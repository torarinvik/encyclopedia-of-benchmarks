package bp_ordered_tree_navigation

import "core:c"

MAX_N :: 31
MAX_Q :: 32
MAX_INPUT :: 129
MAX_BITS :: 2 * MAX_N
MAX_OUTPUT_WORDS :: 4 + MAX_Q

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
bp_ordered_tree_navigation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	bit_length := 2 * n
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
		opcode, first, second := input[offset], input[offset + 1], input[offset + 2]
		if opcode == 0 || opcode == 1 {
			if first < 0 || first > i64(bit_length) || second < -i64(bit_length) || second > i64(bit_length) do return -1
		} else if opcode == 2 {
			if first < 0 || second < first || second >= i64(bit_length) do return -1
		} else if opcode == 3 || opcode == 4 || opcode == 5 {
			if first < 0 || first >= i64(bit_length) || second != 0 do return -1
		} else do return -1
	}

	bits: [MAX_BITS]u8
	stack_node, next_child: [MAX_N + 1]int
	bit_count, depth := 1, 1
	bits[0] = 1
	next_child[0] = 1
	for depth > 0 {
		frame := depth - 1
		node := stack_node[frame]
		child := next_child[frame]
		for child < n && parent[child] != node do child += 1
		if child < n {
			next_child[frame] = child + 1
			bits[bit_count] = 1
			bit_count += 1
			stack_node[depth] = child
			next_child[depth] = 1
			depth += 1
		} else {
			bits[bit_count] = 0
			bit_count += 1
			depth -= 1
		}
	}
	if bit_count != bit_length do return -1

	excess: [MAX_BITS + 1]i64
	packed: u64 = 0
	for position := 0; position < bit_length; position += 1 {
		if bits[position] != 0 {
			packed |= u64(1) << u64(position)
			excess[position + 1] = excess[position] + 1
		} else {
			excess[position + 1] = excess[position] - 1
		}
	}
	for index := 0; index < q; index += 1 {
		offset := query_base + 3 * index
		opcode, first := input[offset], int(input[offset + 1])
		if opcode == 3 && bits[first] == 0 do return -1
		if opcode == 4 && bits[first] != 0 do return -1
		if opcode == 5 && bits[first] == 0 do return -1
	}

	words: [MAX_OUTPUT_WORDS]i64
	words[0], words[1], words[2], words[3] = n_value, i64(bit_length), i64(packed), q_value
	for index := 0; index < q; index += 1 {
		offset := query_base + 3 * index
		opcode, first, second := input[offset], int(input[offset + 1]), input[offset + 2]
		answer: i64 = -1
		if opcode == 0 || opcode == 1 {
			target := excess[first] + second
			if opcode == 0 {
				answer = i64(bit_length + 1)
				for position := first + 1; position <= bit_length; position += 1 {
					if excess[position] == target { answer = i64(position); break }
				}
			} else {
				answer = 0
				position := first
				for position > 0 {
					position -= 1
					if excess[position] == target { answer = i64(position); break }
				}
			}
		} else if opcode == 2 {
			right := int(second)
			best := first
			for position := first + 1; position <= right; position += 1 {
				if excess[position + 1] < excess[best + 1] { best = position }
			}
			answer = i64(best)
		} else if opcode == 3 {
			target := excess[first + 1] - 1
			for position := first + 2; position <= bit_length; position += 1 {
				if excess[position] == target { answer = i64(position - 1); break }
			}
		} else if opcode == 4 {
			target := excess[first + 1]
			position := first + 1
			for position > 0 {
				position -= 1
				if excess[position] == target { answer = i64(position); break }
			}
		} else if first == 0 {
			answer = -1
		} else {
			target := excess[first + 1] - 2
			position := first + 1
			for position > 0 {
				position -= 1
				if excess[position] == target { answer = i64(position); break }
			}
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
