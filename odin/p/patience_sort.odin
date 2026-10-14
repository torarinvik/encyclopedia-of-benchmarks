package patience_sort

import "core:c"

node_less :: proc "contextless" (keys: [^]i64, left, right: int) -> bool {
	return keys[left] < keys[right] || (keys[left] == keys[right] && left < right)
}

sift_down :: proc "contextless" (keys: [^]i64, heap: [^]int, heap_length, root_value: int) {
	root := root_value
	for root < heap_length / 2 {
		child := root * 2 + 1
		if child + 1 < heap_length && node_less(keys, heap[child + 1], heap[child]) do child += 1
		if !node_less(keys, heap[child], heap[root]) do break
		temporary := heap[root]; heap[root] = heap[child]; heap[child] = temporary
		root = child
	}
}

@(export)
patience_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 || length > 1024 do return
	n := int(length)
	keys: [1024]i64
	pile_tops: [1024]int
	next_in_pile: [1024]int
	heap: [1024]int
	for index := 0; index < n; index += 1 {
		keys[index] = values[index]
		next_in_pile[index] = n
	}
	pile_count := 0
	for index := 0; index < n; index += 1 {
		low := 0
		high := pile_count
		for low < high {
			middle := low + (high - low) / 2
			if keys[pile_tops[middle]] >= keys[index] do high = middle
			else do low = middle + 1
		}
		if low == pile_count {
			pile_tops[pile_count] = index
			pile_count += 1
		} else {
			next_in_pile[index] = pile_tops[low]
			pile_tops[low] = index
		}
	}
	for pile := 0; pile < pile_count; pile += 1 do heap[pile] = pile_tops[pile]
	heap_length := pile_count
	for start := heap_length / 2; start > 0; {
		start -= 1
		sift_down(&keys[0], &heap[0], heap_length, start)
	}
	output := 0
	for heap_length > 0 {
		node := heap[0]
		values[output] = keys[node]
		output += 1
		successor := next_in_pile[node]
		if successor < n do heap[0] = successor
		else {
			heap_length -= 1
			if heap_length > 0 do heap[0] = heap[heap_length]
		}
		if heap_length > 0 { sift_down(&keys[0], &heap[0], heap_length, 0) }
	}
}
