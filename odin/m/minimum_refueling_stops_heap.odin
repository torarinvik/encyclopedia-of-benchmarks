// Greedy minimum refueling stops using a bounded max-heap.
package minimum_refueling_stops_heap

import "core:c"

@(export)
minimum_refueling_stops_heap :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 20 do return -2
	target := input[0]
	start_fuel := input[1]
	count_value := input[2]
	if target < 1 || target > 2000 || start_fuel < 0 || start_fuel > 2000 || count_value < 0 || count_value > 8 do return -2
	count := int(count_value)
	if int(length) != 3 + 2 * count do return -2
	previous: i64 = 0
	for i := 0; i < count; i += 1 {
		position := input[3 + 2 * i]
		fuel := input[4 + 2 * i]
		if position <= previous || position >= target || fuel < 1 || fuel > 2000 do return -2
		previous = position
	}

	heap: [8]i64 = {}
	heap_length := 0
	next_station := 0
	reach := start_fuel
	stops: i64 = 0
	for reach < target {
		for next_station < count && input[3 + 2 * next_station] <= reach {
			child := heap_length
			heap_length += 1
			heap[child] = input[4 + 2 * next_station]
			for child > 0 {
				parent := (child - 1) / 2
				if heap[parent] >= heap[child] do break
				temporary := heap[parent]
				heap[parent] = heap[child]
				heap[child] = temporary
				child = parent
			}
			next_station += 1
		}
		if heap_length == 0 do return -1
		maximum := heap[0]
		heap_length -= 1
		if heap_length > 0 {
			heap[0] = heap[heap_length]
			parent := 0
			for {
				left := 2 * parent + 1
				right := left + 1
				if left >= heap_length do break
				child := left
				if right < heap_length && heap[right] > heap[left] do child = right
				if heap[parent] >= heap[child] do break
				temporary := heap[parent]
				heap[parent] = heap[child]
				heap[child] = temporary
				parent = child
			}
		}
		reach += maximum
		stops += 1
	}
	return stops
}
