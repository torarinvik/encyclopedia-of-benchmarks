module dfuds_ordered_tree_navigation

const max_n = 31
const max_q = 32
const max_input = 129
const max_bits = 2 * max_n
const max_output_words = 4 + max_q

fn bit_at(bits u64, position int) bool {
	return ((bits >> (position - 1)) & u64(1)) != 0
}

fn find_close(bits u64, bit_length int, start int) int {
	mut balance := 0
	for position in start .. bit_length + 1 {
		if bit_at(bits, position) { balance++ } else { balance-- }
		if balance == 0 { return position }
	}
	return bit_length + 1
}

fn find_open(bits u64, position int) int {
	if bit_at(bits, position) { return position }
	mut balance := 0
	mut candidate := position
	for candidate > 0 {
		if bit_at(bits, candidate) { balance-- } else { balance++ }
		if balance == 0 { return candidate }
		candidate--
	}
	return 0
}

fn previous_zero(bits u64, position int) int {
	mut candidate := position
	for candidate > 1 {
		if !bit_at(bits, candidate - 1) { return candidate - 1 }
		candidate--
	}
	return 0
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'dfuds_ordered_tree_navigation']
pub fn dfuds_ordered_tree_navigation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
	n := int(n_value)
	q := int(q_value)
	if length != usize(2 + n - 1 + 3 * q) { return -1 }

	mut parent := []int{len: max_n}
	for vertex in 1 .. n {
		value := unsafe { input[1 + vertex] }
		if value < 0 || value >= i64(vertex) { return -1 }
		parent[vertex] = int(value)
	}
	query_base := n + 1
	for index in 0 .. q {
		offset := query_base + 3 * index
		opcode := unsafe { input[offset] }
		node := unsafe { input[offset + 1] }
		argument := unsafe { input[offset + 2] }
		if node < 0 || node >= n_value { return -1 }
		if opcode == 0 || opcode == 2 {
			if argument != 0 { return -1 }
		} else if opcode == 1 {
			if argument < 0 || argument > n_value { return -1 }
		} else { return -1 }
	}

	mut order := []int{len: max_n}
	mut stack_node := []int{len: max_n}
	mut next_child := []int{len: max_n}
	mut order_count := 1
	mut depth := 1
	for depth > 0 {
		frame := depth - 1
		node := stack_node[frame]
		mut child := next_child[frame]
		for child < n && parent[child] != node { child++ }
		if child < n {
			next_child[frame] = child + 1
			order[order_count] = child
			order_count++
			stack_node[depth] = child
			next_child[depth] = 1
			depth++
		} else { depth-- }
	}
	if order_count != n { return -1 }

	mut descriptor := []int{len: max_n}
	mut position_to_node := []int{len: max_bits + 2, init: -1}
	mut packed := u64(1)
	mut bit_length := 1
	for node in 0 .. n {
		mut degree := 0
		for child in 1 .. n {
			if parent[child] == order[node] { degree++ }
		}
		descriptor[node] = bit_length + 1
		position_to_node[descriptor[node]] = node
		for _ in 0 .. degree {
			packed |= u64(1) << bit_length
			bit_length++
		}
		bit_length++
	}
	if bit_length != 2 * n { return -1 }

	mut words := []i64{len: max_output_words}
	words[0] = n_value
	words[1] = i64(bit_length)
	words[2] = i64(packed)
	words[3] = q_value
	for index in 0 .. q {
		offset := query_base + 3 * index
		opcode := unsafe { input[offset] }
		node := int(unsafe { input[offset + 1] })
		argument := unsafe { input[offset + 2] }
		start := descriptor[node]
		mut degree := 0
		for start + degree <= bit_length && bit_at(packed, start + degree) { degree++ }
		mut answer := i64(-1)
		if opcode == 0 {
			answer = i64(degree)
		} else if opcode == 1 {
			if argument < i64(degree) {
				target := start + degree - (int(argument) + 1)
				child_start := find_close(packed, bit_length, target) + 1
				if child_start > max_bits + 1 || position_to_node[child_start] < 0 { return -1 }
				answer = i64(position_to_node[child_start])
			}
		} else if node != 0 {
			matched_open := find_open(packed, start - 1)
			parent_position := previous_zero(packed, matched_open) + 1
			if parent_position == 1 { answer = 0 }
			else if parent_position <= max_bits + 1 && position_to_node[parent_position] >= 0 {
				answer = i64(position_to_node[parent_position])
			} else { return -1 }
		}
		words[4 + index] = answer
	}

	required := 8 * (4 + q)
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. 4 + q { write_i64_le(mut output, 8 * index, words[index]) }
	return i64(required)
}
