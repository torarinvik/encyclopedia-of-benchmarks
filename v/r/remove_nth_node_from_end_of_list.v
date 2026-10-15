module remove_nth_node_from_end_of_list

const max_list_length = 1024
const end_node_index = max_list_length

// Remove a node by one-based distance from the tail in an index-based list.
@[export: 'remove_nth_node_from_end_of_list']
pub fn remove_nth_node_from_end_of_list(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_list_length + 1 { return -1 }
	list_length := length - 1
	for index in 0 .. list_length {
		value := unsafe { input[index + 1] }
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	position := unsafe { input[0] }
	if position < 1 || u64(position) > u64(list_length) { return -1 }

	mut next_node := [max_list_length]usize{}
	for index in 0 .. list_length {
		if index + 1 < list_length { next_node[index] = index + 1 }
		else { next_node[index] = end_node_index }
	}
	mut node := usize(0)
	mut counted := usize(0)
	for _ in 0 .. list_length {
		if node == end_node_index { return -1 }
		node = next_node[node]
		counted++
	}
	if node != end_node_index || counted != list_length { return -1 }

	steps_to_target := counted - usize(position)
	mut before := usize(end_node_index)
	node = 0
	for _ in 0 .. steps_to_target {
		before = node
		node = next_node[node]
	}
	mut head := usize(0)
	if before == end_node_index { head = next_node[node] }
	else { next_node[before] = next_node[node] }

	output_count := counted - 1
	output_bytes := output_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && unsafe { output == nil }) { return -2 }
	node = head
	mut written := usize(0)
	for _ in 0 .. output_count {
		if node == end_node_index { return -1 }
		bits := u32(i32(unsafe { input[node + 1] }))
		for byte in 0 .. 4 {
			unsafe { output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff) }
		}
		node = next_node[node]
		written++
	}
	if node != end_node_index || written != output_count { return -1 }
	return i64(written)
}
