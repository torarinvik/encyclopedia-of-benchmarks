const max_initial_nodes = 12
const max_operations = 16
const max_known_ids = max_initial_nodes + 2 * max_operations
const max_parseable_input_length = 64
const max_output_words = 81
const max_output_bytes = 648

fn find_id(ids []i64, count int, id i64) int {
	for index in 0 .. count {
		if ids[index] == id { return index }
	}
	return -1
}

fn ensure_id(mut ids []i64, mut declared []bool, mut count int, id i64) int {
	found := find_id(ids, count, id)
	if found >= 0 { return found }
	if count >= max_known_ids { return -1 }
	index := count
	count++
	ids[index] = id
	declared[index] = false
	return index
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'unweighted_graph']
pub fn unweighted_graph(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > max_parseable_input_length { return -1 }
		if (input[0] != 0 && input[0] != 1) || input[1] < 0 || input[1] > max_initial_nodes ||
			input[2] < 0 || input[2] > max_operations { return -1 }
		directed := input[0] == 1
		initial_count := int(input[1])
		operation_count := int(input[2])
		if input_length != usize(3 + initial_count + operation_count * 3) { return -1 }

		mut ids := [max_known_ids]i64{}
		mut declared := [max_known_ids]bool{}
		mut adjacency := [max_known_ids * max_known_ids]bool{}
		mut known_count := 0
		for index in 0 .. initial_count {
			node := input[3 + index]
			if node < -2147483648 || node > 2147483647 || find_id(ids[..], known_count, node) >= 0 { return -1 }
			slot := ensure_id(mut ids[..], mut declared[..], mut known_count, node)
			if slot < 0 { return -1 }
			declared[slot] = true
		}

		mut result := [max_output_words]i64{}
		mut result_count := 0
		operations_offset := 3 + initial_count
		for index in 0 .. operation_count {
			offset := operations_offset + index * 3
			op := input[offset]
			first := input[offset + 1]
			second := input[offset + 2]
			if first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647 { return -1 }
			if op == 0 {
				if second != 0 { return -1 }
				existing := find_id(ids[..], known_count, first)
				if existing >= 0 && declared[existing] { return -1 }
				slot := ensure_id(mut ids[..], mut declared[..], mut known_count, first)
				if slot < 0 { return -1 }
				declared[slot] = true
			} else if op == 1 {
				from := find_id(ids[..], known_count, first)
				if from < 0 || !declared[from] { return -1 }
				mut to := find_id(ids[..], known_count, second)
				if !directed && (to < 0 || !declared[to]) { return -1 }
				if to < 0 { to = ensure_id(mut ids[..], mut declared[..], mut known_count, second) }
				if to < 0 || adjacency[from * max_known_ids + to] { return -1 }
				adjacency[from * max_known_ids + to] = true
				if !directed { adjacency[to * max_known_ids + from] = true }
			} else if op == 2 {
				if second != 0 { return -1 }
				node := find_id(ids[..], known_count, first)
				if node < 0 || !declared[node] { return -1 }
				mut sorted := [max_known_ids]i64{}
				mut neighbor_count := 0
				for neighbor in 0 .. known_count {
					if adjacency[node * max_known_ids + neighbor] {
						sorted[neighbor_count] = ids[neighbor]
						neighbor_count++
					}
				}
				for left in 1 .. neighbor_count {
					value := sorted[left]
					mut right := left
					for right > 0 && sorted[right - 1] > value {
						sorted[right] = sorted[right - 1]
						right--
					}
					sorted[right] = value
				}
				if result_count + 2 + neighbor_count > max_output_words { return -1 }
				result[result_count] = first
				result[result_count + 1] = i64(neighbor_count)
				result_count += 2
				for neighbor in 0 .. neighbor_count {
					result[result_count] = sorted[neighbor]
					result_count++
				}
			} else { return -1 }
		}

		output_bytes := result_count * 8
		if output_bytes > max_output_bytes { return -1 }
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. result_count { put_i64_le(mut output, index * 8, result[index]) }
		return i64(output_bytes)
	}
}
