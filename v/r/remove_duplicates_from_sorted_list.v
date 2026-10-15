module remove_duplicates_from_sorted_list

const max_nodes = 1024

// Unlink later nodes with the same value in a sorted indexed list.
@[export: 'remove_duplicates_from_sorted_list']
pub fn remove_duplicates_from_sorted_list(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_nodes { return -1 }
	unsafe {
		for index in 0 .. length {
			value := input[index]
			if value < -2147483648 || value > 2147483647 || (index > 0 && input[index - 1] > value) { return -1 }
		}
		mut next_node := []usize{len: max_nodes + 1, init: usize(0)}
		for index in 0 .. length { next_node[index] = index + 1 }
		next_node[length] = length
		mut current := usize(0)
		for current != length && next_node[current] != length {
			next := next_node[current]
			if input[current] == input[next] { next_node[current] = next_node[next] } else { current = next }
		}
		mut survivor_count := usize(0)
		mut node := usize(0)
		for node != length {
			survivor_count++
			node = next_node[node]
		}
		output_bytes := survivor_count * 4
		if output_capacity < output_bytes { return -2 }
		mut written := usize(0)
		node = usize(0)
		for node != length {
			bits := u32(i32(input[node]))
			for byte in 0 .. 4 { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
			written++
			node = next_node[node]
		}
		if written != survivor_count { return -1 }
		return i64(written)
	}
}
