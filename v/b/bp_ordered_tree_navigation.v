module bp_ordered_tree_navigation

const max_n = 31
const max_q = 32
const max_input = 129
const max_bits = 2 * max_n
const max_output_words = 4 + max_q

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'bp_ordered_tree_navigation']
pub fn bp_ordered_tree_navigation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || q_value < 0 || q_value > max_q { return -1 }
	n := int(n_value)
	q := int(q_value)
	bit_length := 2 * n
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
		first := unsafe { input[offset + 1] }
		second := unsafe { input[offset + 2] }
		if opcode == 0 || opcode == 1 {
			if first < 0 || first > i64(bit_length) || second < -i64(bit_length) || second > i64(bit_length) { return -1 }
		} else if opcode == 2 {
			if first < 0 || second < first || second >= i64(bit_length) { return -1 }
		} else if opcode == 3 || opcode == 4 || opcode == 5 {
			if first < 0 || first >= i64(bit_length) || second != 0 { return -1 }
		} else { return -1 }
	}

	mut bits := []int{len: max_bits}
	mut stack_node := []int{len: max_n + 1}
	mut next_child := []int{len: max_n + 1}
	mut bit_count := 1
	mut depth := 1
	bits[0] = 1
	next_child[0] = 1
	for depth > 0 {
		frame := depth - 1
		node := stack_node[frame]
		mut child := next_child[frame]
		for child < n && parent[child] != node { child++ }
		if child < n {
			next_child[frame] = child + 1
			bits[bit_count] = 1
			bit_count++
			stack_node[depth] = child
			next_child[depth] = 1
			depth++
		} else {
			bits[bit_count] = 0
			bit_count++
			depth--
		}
	}
	if bit_count != bit_length { return -1 }

	mut excess := []i64{len: max_bits + 1}
	mut packed := u64(0)
	for position in 0 .. bit_length {
		if bits[position] != 0 {
			packed |= u64(1) << position
			excess[position + 1] = excess[position] + 1
		} else {
			excess[position + 1] = excess[position] - 1
		}
	}
	for index in 0 .. q {
		offset := query_base + 3 * index
		opcode := unsafe { input[offset] }
		first := int(unsafe { input[offset + 1] })
		if opcode == 3 && bits[first] == 0 { return -1 }
		if opcode == 4 && bits[first] != 0 { return -1 }
		if opcode == 5 && bits[first] == 0 { return -1 }
	}

	mut words := []i64{len: max_output_words}
	words[0] = n_value
	words[1] = i64(bit_length)
	words[2] = i64(packed)
	words[3] = q_value
	for index in 0 .. q {
		offset := query_base + 3 * index
		opcode := unsafe { input[offset] }
		first := int(unsafe { input[offset + 1] })
		second := unsafe { input[offset + 2] }
		mut answer := i64(-1)
		if opcode == 0 || opcode == 1 {
			target := excess[first] + second
			if opcode == 0 {
				answer = i64(bit_length + 1)
				for position in first + 1 .. bit_length + 1 {
					if excess[position] == target { answer = i64(position); break }
				}
			} else {
				answer = 0
				mut position := first
				for position > 0 {
					position--
					if excess[position] == target { answer = i64(position); break }
				}
			}
		} else if opcode == 2 {
			right := int(second)
			mut best := first
			for position in first + 1 .. right + 1 {
				if excess[position + 1] < excess[best + 1] { best = position }
			}
			answer = i64(best)
		} else if opcode == 3 {
			target := excess[first + 1] - 1
			for position in first + 2 .. bit_length + 1 {
				if excess[position] == target { answer = i64(position - 1); break }
			}
		} else if opcode == 4 {
			target := excess[first + 1]
			mut position := first + 1
			for position > 0 {
				position--
				if excess[position] == target { answer = i64(position); break }
			}
		} else if first == 0 {
			answer = -1
		} else {
			target := excess[first + 1] - 2
			mut position := first + 1
			for position > 0 {
				position--
				if excess[position] == target { answer = i64(position); break }
			}
		}
		words[4 + index] = answer
	}
	required := 8 * (4 + q)
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. 4 + q {
		write_i64_le(mut output, 8 * index, words[index])
	}
	return i64(required)
}
