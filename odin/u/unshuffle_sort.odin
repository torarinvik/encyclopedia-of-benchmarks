package unshuffle_sort

import "core:c"

MAX_ITEMS :: 1024
NONE :: u32(MAX_ITEMS)
Node_Table :: [MAX_ITEMS]u32

pile_less :: proc(pile_front: [^]u32, input_values: [^]i64,
		left, right: u32) -> bool {
	left_node := pile_front[left]
	right_node := pile_front[right]
	if input_values[left_node] != input_values[right_node] {
		return input_values[left_node] < input_values[right_node]
	}
	return left < right
}

sift_down :: proc(pile_front: [^]u32, input_values: [^]i64,
		heap: [^]u32, heap_size, start: u32) {
	position := start
	for position*2+1 < heap_size {
		child := position*2+1
		if child+1 < heap_size && pile_less(pile_front, input_values, heap[child+1], heap[child]) {
			child += 1
		}
		if !pile_less(pile_front, input_values, heap[child], heap[position]) {
			break
		}
		heap[position], heap[child] = heap[child], heap[position]
		position = child
	}
}

@(export)
unshuffle_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if values == nil || scratch == nil || length < 2 || length > MAX_ITEMS do return
	n := int(length)
	var previous, next, pile_front, pile_back, heap: Node_Table
	pile_count := u32(0)

	for node := 0; node < n; node += 1 {
		previous[node] = NONE
		next[node] = NONE
		pile := u32(0)
		for pile < pile_count {
			front := pile_front[pile]
			back := pile_back[pile]
			if values[node] <= values[front] {
				next[node] = front
				previous[front] = u32(node)
				pile_front[pile] = u32(node)
				break
			}
			if values[node] >= values[back] {
				previous[node] = back
				next[back] = u32(node)
				pile_back[pile] = u32(node)
				break
			}
			pile += 1
		}
		if pile == pile_count {
			pile_front[pile_count] = u32(node)
			pile_back[pile_count] = u32(node)
			pile_count += 1
		}
	}

	heap_size := u32(0)
	for pile := u32(0); pile < pile_count; pile += 1 {
		position := heap_size
		heap[position] = pile
		heap_size += 1
		for position > 0 {
			parent := (position - 1) / 2
			if !pile_less(&pile_front[0], &values[0], heap[position], heap[parent]) {
				break
			}
			heap[position], heap[parent] = heap[parent], heap[position]
			position = parent
		}
	}

	output := 0
	for heap_size > 0 {
		pile := heap[0]
		node := pile_front[pile]
		scratch[output] = values[node]
		output += 1
		successor := next[node]
		if successor != NONE {
			previous[successor] = NONE
			next[node] = NONE
			pile_front[pile] = successor
		} else {
			pile_front[pile] = NONE
			pile_back[pile] = NONE
			heap_size -= 1
			if heap_size > 0 {
				heap[0] = heap[heap_size]
			}
		}
		if heap_size > 0 {
			sift_down(&pile_front[0], &values[0], &heap[0], heap_size, 0)
		}
	}
	for index := 0; index < n; index += 1 {
		values[index] = scratch[index]
	}
}
