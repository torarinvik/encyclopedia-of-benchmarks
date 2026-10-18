package unweighted_graph

import "core:c"

MAX_INITIAL_NODES :: 12
MAX_OPERATIONS :: 16
MAX_KNOWN_IDS :: MAX_INITIAL_NODES + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH :: 64
MAX_OUTPUT_WORDS :: 81
MAX_OUTPUT_BYTES :: 648

find_id :: proc(ids: []i64, count: int, id: i64) -> int {
	for index := 0; index < count; index += 1 {
		if ids[index] == id do return index
	}
	return -1
}

ensure_id :: proc(ids: []i64, declared: []bool, count: ^int, id: i64) -> int {
	found := find_id(ids, count^, id)
	if found >= 0 do return found
	if count^ >= MAX_KNOWN_IDS do return -1
	index := count^
	count^ += 1
	ids[index] = id
	declared[index] = false
	return index
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
unweighted_graph :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if (input[0] != 0 && input[0] != 1) || input[1] < 0 || input[1] > MAX_INITIAL_NODES ||
		input[2] < 0 || input[2] > MAX_OPERATIONS do return -1
	directed := input[0] == 1
	initial_count := int(input[1])
	operation_count := int(input[2])
	if input_length != c.size_t(3 + initial_count + operation_count * 3) do return -1

	ids: [MAX_KNOWN_IDS]i64
	declared: [MAX_KNOWN_IDS]bool
	adjacency: [MAX_KNOWN_IDS * MAX_KNOWN_IDS]bool
	known_count := 0
	for index := 0; index < initial_count; index += 1 {
		node := input[3 + index]
		if node < -2147483648 || node > 2147483647 || find_id(ids[:], known_count, node) >= 0 do return -1
		slot := ensure_id(ids[:], declared[:], &known_count, node)
		if slot < 0 do return -1
		declared[slot] = true
	}

	result: [MAX_OUTPUT_WORDS]i64
	result_count := 0
	operations_offset := 3 + initial_count
	for index := 0; index < operation_count; index += 1 {
		offset := operations_offset + index * 3
		op := input[offset]
		first := input[offset + 1]
		second := input[offset + 2]
		if first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647 do return -1
		if op == 0 {
			if second != 0 do return -1
			existing := find_id(ids[:], known_count, first)
			if existing >= 0 && declared[existing] do return -1
			slot := ensure_id(ids[:], declared[:], &known_count, first)
			if slot < 0 do return -1
			declared[slot] = true
		} else if op == 1 {
			from := find_id(ids[:], known_count, first)
			if from < 0 || !declared[from] do return -1
			to := find_id(ids[:], known_count, second)
			if !directed && (to < 0 || !declared[to]) do return -1
			if to < 0 { to = ensure_id(ids[:], declared[:], &known_count, second) }
			if to < 0 || adjacency[from * MAX_KNOWN_IDS + to] do return -1
			adjacency[from * MAX_KNOWN_IDS + to] = true
			if !directed { adjacency[to * MAX_KNOWN_IDS + from] = true }
		} else if op == 2 {
			if second != 0 do return -1
			node := find_id(ids[:], known_count, first)
			if node < 0 || !declared[node] do return -1
			sorted: [MAX_KNOWN_IDS]i64
			neighbor_count := 0
			for neighbor := 0; neighbor < known_count; neighbor += 1 {
				if adjacency[node * MAX_KNOWN_IDS + neighbor] {
					sorted[neighbor_count] = ids[neighbor]
					neighbor_count += 1
				}
			}
			for left := 1; left < neighbor_count; left += 1 {
				value := sorted[left]
				right := left
				for right > 0 && sorted[right - 1] > value {
					sorted[right] = sorted[right - 1]
					right -= 1
				}
				sorted[right] = value
			}
			if result_count + 2 + neighbor_count > MAX_OUTPUT_WORDS do return -1
			result[result_count] = first
			result[result_count + 1] = i64(neighbor_count)
			result_count += 2
			for neighbor := 0; neighbor < neighbor_count; neighbor += 1 {
				result[result_count] = sorted[neighbor]
				result_count += 1
			}
		} else {
			return -1
		}
	}

	output_bytes := result_count * 8
	if output_bytes > MAX_OUTPUT_BYTES do return -1
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < result_count; index += 1 {
		write_i64_le(output, index * 8, result[index])
	}
	return i64(output_bytes)
}
