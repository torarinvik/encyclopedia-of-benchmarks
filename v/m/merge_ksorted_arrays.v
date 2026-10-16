module merge_ksorted_arrays

const max_arrays = 16
const max_total_values = 128
const max_parseable_length = usize(146)
const min_value = i64(-1_000_000)
const max_value = i64(1_000_000)
const checksum_offset = i64(1_000_001)

struct HeapNode {
	value i64
	array_index int
	element_index int
}

fn node_less(left HeapNode, right HeapNode) bool {
	if left.value != right.value { return left.value < right.value }
	if left.array_index != right.array_index { return left.array_index < right.array_index }
	return left.element_index < right.element_index
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

@[export: 'merge_ksorted_arrays']
pub fn merge_ksorted_arrays(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if values[0] < 1 || values[0] > i64(max_arrays) { return -1 }
		array_count := int(values[0])
		mut starts := [max_arrays]int{}
		mut lengths := [max_arrays]int{}
		mut position := 1
		mut total_values := 0
		for array_index in 0 .. array_count {
			if position >= int(length) { return -1 }
			declared := values[position]
			position++
			if declared < 0 || declared > i64(max_total_values - total_values) { return -1 }
			array_length := int(declared)
			if array_length > int(length) - position { return -1 }
			starts[array_index] = position
			lengths[array_index] = array_length
			for index in 0 .. array_length {
				value := values[position + index]
				if value < min_value || value > max_value ||
					(index > 0 && values[position + index - 1] > value) { return -1 }
			}
			position += array_length
			total_values += array_length
		}
		if position != int(length) { return -1 }

		mut heap := []HeapNode{cap: max_arrays}
		for array_index in 0 .. array_count {
			if lengths[array_index] > 0 {
				heap_push(mut heap, HeapNode{value: values[starts[array_index]], array_index: array_index, element_index: 0})
			}
		}
		mut checksum := i64(0)
		mut merged_index := i64(0)
		for heap.len > 0 {
			node := heap_pop(mut heap)
			checksum += (merged_index + 1) * (node.value + checksum_offset)
			merged_index++
			next_index := node.element_index + 1
			if next_index < lengths[node.array_index] {
				heap_push(mut heap, HeapNode{value: values[starts[node.array_index] + next_index], array_index: node.array_index, element_index: next_index})
			}
		}
		return checksum
	}
}
