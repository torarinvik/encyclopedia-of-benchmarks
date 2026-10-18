module undirected_adjacency_list_graph

const max_nodes = 8
const max_operations = 24
const max_parseable_input_length = 98
const max_output_words = 144

fn push_word(mut words [144]i64, mut count int, value i64) {
	words[count] = value
	count++
}

fn push_record(mut words [144]i64, mut count int, opcode i64, payload [9]i64, payload_count int) {
	push_word(mut words, mut count, opcode)
	push_word(mut words, mut count, i64(payload_count))
	for index in 0 .. payload_count {
		push_word(mut words, mut count, payload[index])
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'undirected_adjacency_list_graph']
pub fn undirected_adjacency_list_graph(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_input_length { return -1 }
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + 4 * operation_count) { return -1 }

		mut words := [144]i64{}
		mut word_count := 0
		mut edge_weights := [8][8]i64{}
		mut has_edge := [8][8]bool{}
		mut node_count := 0

		for operation_index in 0 .. operation_count {
			base := 1 + 4 * operation_index
			opcode := input[base]
			first := input[base + 1]
			second := input[base + 2]
			third := input[base + 3]
			if opcode < 0 || opcode > 4 { return -1 }

			if opcode == 0 || opcode == 4 {
				if first != 0 || second != 0 || third != 0 { return -1 }
			} else if opcode == 1 {
				if first < -2147483648 || first > 2147483647 || second < -2147483648 ||
					second > 2147483647 || third < -2147483648 || third > 2147483647 { return -1 }
			} else if opcode == 2 {
				if first < -2147483648 || first > 2147483647 || second != 0 || third != 0 { return -1 }
			} else if first < -2147483648 || first > 2147483647 || second < -2147483648 ||
				second > 2147483647 || third != 0 { return -1 }

			if opcode == 0 {
				if node_count >= max_nodes { return -1 }
				mut payload := [9]i64{}
				payload[0] = i64(node_count)
				push_record(mut words, mut word_count, opcode, payload, 1)
				node_count++
			} else if opcode == 1 {
				mut added := false
				if first >= 0 && first < i64(node_count) && second >= 0 && second < i64(node_count) {
					origin := int(first)
					destination := int(second)
					if !has_edge[origin][destination] {
						has_edge[origin][destination] = true
						has_edge[destination][origin] = true
						edge_weights[origin][destination] = third
						edge_weights[destination][origin] = third
						added = true
					}
				}
				mut payload := [9]i64{}
				payload[0] = if added { i64(1) } else { i64(0) }
				push_record(mut words, mut word_count, opcode, payload, 1)
			} else if opcode == 2 {
				if first < 0 || first >= i64(node_count) { return -1 }
				origin := int(first)
				mut payload := [9]i64{}
				mut neighbor_count := 0
				for neighbor in 0 .. node_count {
					if has_edge[origin][neighbor] {
						payload[neighbor_count + 1] = i64(neighbor)
						neighbor_count++
					}
				}
				payload[0] = i64(neighbor_count)
				push_record(mut words, mut word_count, opcode, payload, neighbor_count + 1)
			} else if opcode == 3 {
				if first < 0 || first >= i64(node_count) { return -1 }
				origin := int(first)
				mut present := false
				mut weight := i64(0)
				if second >= 0 && second < i64(node_count) && has_edge[origin][int(second)] {
					present = true
					weight = edge_weights[origin][int(second)]
				}
				mut payload := [9]i64{}
				payload[0] = if present { i64(1) } else { i64(0) }
				payload[1] = weight
				push_record(mut words, mut word_count, opcode, payload, 2)
			} else {
				mut payload := [9]i64{}
				payload[0] = i64(node_count)
				push_record(mut words, mut word_count, opcode, payload, 1)
			}
		}

		output_bytes := word_count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index in 0 .. word_count {
			store_i64_le(mut output, index * 8, words[index])
		}
		return i64(output_bytes)
	}
}
