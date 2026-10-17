module merge_ksorted_linked_list

const max_lists = 16
const max_total_nodes = 128
const max_input_length = 145
const max_output_bytes = 512

struct HeapNode {
	value i64
	list_index int
	node_index int
}

fn node_less(left HeapNode, right HeapNode) bool {
	if left.value != right.value { return left.value < right.value }
	if left.list_index != right.list_index { return left.list_index < right.list_index }
	return left.node_index < right.node_index
}

fn heap_push(mut heap []HeapNode, node HeapNode) {
	heap << node
	mut index := heap.len - 1
	for index > 0 {
		parent := (index - 1) / 2
		if !node_less(node, heap[parent]) { break }
		heap[index] = heap[parent]
		index = parent
	}
	heap[index] = node
}

fn heap_pop(mut heap []HeapNode) HeapNode {
	result := heap[0]
	last := heap.pop()
	if heap.len > 0 {
		mut index := 0
		for index < heap.len / 2 {
			mut child := 2 * index + 1
			if child + 1 < heap.len && node_less(heap[child + 1], heap[child]) { child++ }
			if !node_less(heap[child], last) { break }
			heap[index] = heap[child]
			index = child
		}
		heap[index] = last
	}
	return result
}

fn put_i32_le(mut output &u8, offset int, value i64) {
	mut bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'merge_ksorted_linked_list']
pub fn merge_ksorted_linked_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > usize(max_input_length) { return -1 }
		if input[0] < 0 || input[0] > max_lists { return -1 }
		list_count := int(input[0])
		mut starts := [max_lists]int{init: 0}
		mut lengths := [max_lists]int{init: 0}
		mut position := 1
		mut total_nodes := 0
		for list_index := 0; list_index < list_count; list_index++ {
			if position >= int(length) { return -1 }
			declared := input[position]
			position++
			if declared < 0 || declared > i64(max_total_nodes - total_nodes) { return -1 }
			list_length := int(declared)
			if list_length > int(length) - position { return -1 }
			starts[list_index] = position
			lengths[list_index] = list_length
			for node := 0; node < list_length; node++ {
				value := input[position + node]
				if value < -2147483648 || value > 2147483647 ||
					(node > 0 && input[position + node - 1] > value) { return -1 }
			}
			position += list_length
			total_nodes += list_length
		}
		if position != int(length) { return -1 }

		output_bytes := 4 * total_nodes
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut heap := []HeapNode{cap: max_lists}
		for list_index := 0; list_index < list_count; list_index++ {
			if lengths[list_index] > 0 {
				heap_push(mut heap, HeapNode{value: input[starts[list_index]], list_index: list_index, node_index: 0})
			}
		}

		mut buffer := [max_output_bytes]u8{init: 0}
		mut written := 0
		for heap.len > 0 {
			node := heap_pop(mut heap)
			put_i32_le(mut buffer[0], written, node.value)
			written += 4
			next_index := node.node_index + 1
			if next_index < lengths[node.list_index] {
				heap_push(mut heap, HeapNode{
					value: input[starts[node.list_index] + next_index],
					list_index: node.list_index,
					node_index: next_index,
				})
			}
		}

		for index := 0; index < output_bytes; index++ { output[index] = buffer[index] }
		return i64(output_bytes)
	}
}
