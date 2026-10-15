module remove_linked_list_elements

const max_nodes = 1024

fn remove_chain(input &i64, mut next_node []usize, node usize, sentinel usize, target i64) usize {
	if node == sentinel { return sentinel }
	unsafe {
		next := next_node[node]
		if input[node + 1] == target { return remove_chain(input, mut next_node, next, sentinel, target) }
		next_node[node] = remove_chain(input, mut next_node, next, sentinel, target)
	}
	return node
}

// Recursively unlink matching nodes, then serialize surviving signed 32-bit values.
@[export: 'remove_linked_list_elements']
pub fn remove_linked_list_elements(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length == 0 || length > max_nodes + 1 { return -1 }
	unsafe {
		target := input[0]
		if target < -2147483648 || target > 2147483647 { return -1 }
		mut next_node := []usize{len: max_nodes + 1, init: max_nodes}
		node_count := length - 1
		for index in 0 .. node_count {
			value := input[index + 1]
			if value < -2147483648 || value > 2147483647 { return -1 }
			next_node[index] = index + 1
		}
		head := remove_chain(input, mut next_node, if node_count == 0 { node_count } else { usize(0) }, node_count, target)
		mut survivor_count := usize(0)
		mut node := head
		for node != node_count { survivor_count++; node = next_node[node] }
		output_bytes := survivor_count * 4
		if output_capacity < output_bytes || (output_bytes != 0 && output == nil) { return -2 }
		mut written := usize(0)
		node = head
		for node != node_count {
			bits := u32(i32(input[node + 1]))
			for byte in 0 .. 4 { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
			written++
			node = next_node[node]
		}
		return i64(written)
	}
}
