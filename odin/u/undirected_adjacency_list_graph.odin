package undirected_adjacency_list_graph

import "core:c"

MAX_NODES :: 8
MAX_OPERATIONS :: 24
MAX_PARSEABLE_INPUT_LENGTH :: 98
MAX_OUTPUT_WORDS :: 144

push_word :: proc "contextless" (words: [^]i64, count: ^int, value: i64) {
	words[count^] = value
	count^ += 1
}

push_record :: proc "contextless" (words: [^]i64, count: ^int, opcode: i64,
	payload: [^]i64, payload_count: int) {
	push_word(words, count, opcode)
	push_word(words, count, i64(payload_count))
	for index := 0; index < payload_count; index += 1 {
		push_word(words, count, payload[index])
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
undirected_adjacency_list_graph :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	if int(length) != 1 + 4*operation_count do return -1

	var words: [MAX_OUTPUT_WORDS]i64
	word_count := 0
	var edge_weights: [MAX_NODES][MAX_NODES]i64
	var has_edge: [MAX_NODES][MAX_NODES]bool
	node_count := 0

	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		base := 1 + 4*operation_index
		opcode := input[base]
		first := input[base + 1]
		second := input[base + 2]
		third := input[base + 3]
		if opcode < 0 || opcode > 4 do return -1

		if opcode == 0 || opcode == 4 {
			if first != 0 || second != 0 || third != 0 do return -1
		} else if opcode == 1 {
			if first < -2147483648 || first > 2147483647 ||
				second < -2147483648 || second > 2147483647 ||
				third < -2147483648 || third > 2147483647 do return -1
		} else if opcode == 2 {
			if first < -2147483648 || first > 2147483647 || second != 0 || third != 0 do return -1
		} else if first < -2147483648 || first > 2147483647 ||
			second < -2147483648 || second > 2147483647 || third != 0 do return -1

		if opcode == 0 {
			if node_count >= MAX_NODES do return -1
			payload := [1]i64{i64(node_count)}
			push_record(&words[0], &word_count, opcode, &payload[0], 1)
			node_count += 1
		} else if opcode == 1 {
			added := false
			if first >= 0 && first < i64(node_count) && second >= 0 && second < i64(node_count) {
				origin, destination := int(first), int(second)
				if !has_edge[origin][destination] {
					has_edge[origin][destination] = true
					has_edge[destination][origin] = true
					edge_weights[origin][destination] = third
					edge_weights[destination][origin] = third
					added = true
				}
			}
			payload := [1]i64{if added then 1 else 0}
			push_record(&words[0], &word_count, opcode, &payload[0], 1)
		} else if opcode == 2 {
			if first < 0 || first >= i64(node_count) do return -1
			origin := int(first)
			var payload: [MAX_NODES + 1]i64
			neighbor_count := 0
			for neighbor := 0; neighbor < node_count; neighbor += 1 {
				if has_edge[origin][neighbor] {
					payload[neighbor_count + 1] = i64(neighbor)
					neighbor_count += 1
				}
			}
			payload[0] = i64(neighbor_count)
			push_record(&words[0], &word_count, opcode, &payload[0], neighbor_count + 1)
		} else if opcode == 3 {
			if first < 0 || first >= i64(node_count) do return -1
			origin := int(first)
			present := second >= 0 && second < i64(node_count) && has_edge[origin][int(second)]
			weight: i64 = 0
			if present do weight = edge_weights[origin][int(second)]
			payload := [2]i64{if present then 1 else 0, weight}
			push_record(&words[0], &word_count, opcode, &payload[0], 2)
		} else {
			payload := [1]i64{i64(node_count)}
			push_record(&words[0], &word_count, opcode, &payload[0], 1)
		}
	}

	output_bytes := word_count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < word_count; index += 1 {
		store_i64_le(output, index * 8, words[index])
	}
	return i64(output_bytes)
}
