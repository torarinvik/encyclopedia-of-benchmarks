module delete_middle_node

const max_nodes = 1024

// Delete the floor(n / 2)-indexed node using the source's fast/slow traversal.
@[export: 'delete_middle_node']
pub fn delete_middle_node(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_nodes { return -1 }
	unsafe {
		for index in 0 .. length {
			value := input[index]
			if value < -2147483648 || value > 2147483647 { return -1 }
		}
		if length <= 1 { return 0 }
		mut next_node := []usize{len: max_nodes + 1, init: length}
		for index in 0 .. length { next_node[index] = index + 1 }
		mut node_count := usize(0)
		mut cursor := usize(0)
		for cursor != length { node_count++; cursor = next_node[cursor] }
		mut fast := usize(0)
		mut slow := usize(0)
		mut previous := length
		for next_node[fast] != length && next_node[next_node[fast]] != length {
			previous = slow
			slow = next_node[slow]
			fast = next_node[next_node[fast]]
		}
		if node_count % 2 == 0 { previous = slow; slow = next_node[slow] }
		next_node[previous] = next_node[slow]
		survivor_count := node_count - 1
		output_bytes := survivor_count * 4
		if output_capacity < output_bytes || (output_bytes != 0 && output == nil) { return -2 }
		mut written := usize(0)
		mut node := usize(0)
		for node != length {
			bits := u32(i32(input[node]))
			for byte in 0 .. 4 { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
			written++
			node = next_node[node]
		}
		return i64(written)
	}
}
