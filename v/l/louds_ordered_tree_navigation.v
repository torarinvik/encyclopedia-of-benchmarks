module louds_ordered_tree_navigation

const max_nodes = 32
const max_queries = 32
const max_input_words = 130
const max_output_words = 4 + max_queries

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'louds_ordered_tree_navigation']
pub fn louds_ordered_tree_navigation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_words { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_nodes || q_value < 0 || q_value > max_queries { return -1 }
	n := int(n_value)
	q := int(q_value)
	if length != usize(2 + n - 1 + 3 * q) { return -1 }

	mut parent := []int{len: max_nodes}
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
		if opcode == 0 || opcode == 1 {
			if argument != 0 { return -1 }
		} else if opcode == 2 {
			if argument < 0 || argument > n_value { return -1 }
		} else { return -1 }
	}

	mut order := []int{len: max_nodes}
	order_count := 1
	mut cursor := 0
	for cursor < order_count {
		vertex := order[cursor]
		for child in 1 .. n {
			if parent[child] == vertex {
				order[order_count] = child
				order_count++
			}
		}
		cursor++
	}
	if order_count != n { return -1 }

	mut degree := []int{len: max_nodes}
	for node in 0 .. n {
		for child in 1 .. n {
			if parent[child] == order[node] { degree[node]++ }
		}
	}

	mut packed := u64(0)
	mut bit_length := 0
	for node in 0 .. n {
		for _ in 0 .. degree[node] {
			packed |= u64(1) << bit_length
			bit_length++
		}
		bit_length++
	}

	mut decoded := []int{len: max_nodes}
	mut rank_prefix := []int{len: max_nodes + 1}
	mut bit_position := 0
	mut previous_zero := -1
	for node in 0 .. n {
		for bit_position < bit_length && ((packed >> bit_position) & 1) != 0 {
			bit_position++
		}
		decoded[node] = bit_position - previous_zero - 1
		previous_zero = bit_position
		bit_position++
		rank_prefix[node + 1] = rank_prefix[node] + decoded[node]
	}

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
		mut answer := i64(-1)
		if opcode == 0 {
			answer = i64(decoded[node])
		} else if opcode == 1 {
			if node != 0 {
				for candidate in 0 .. n {
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
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. 4 + q {
		store_i64_le(mut output, 8 * index, words[index])
	}
	return i64(required)
}
