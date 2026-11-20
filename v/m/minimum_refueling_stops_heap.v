// Greedy minimum refueling stops using a bounded max-heap.
@[export: 'minimum_refueling_stops_heap']
pub fn minimum_refueling_stops_heap(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 20 { return -2 }
		target := input[0]
		start_fuel := input[1]
		count_value := input[2]
		if target < 1 || target > 2000 || start_fuel < 0 || start_fuel > 2000 || count_value < 0 || count_value > 8 { return -2 }
		count := int(count_value)
		if int(length) != 3 + 2 * count { return -2 }
		mut previous := i64(0)
		for i in 0 .. count {
			position := input[3 + 2 * i]
			fuel := input[4 + 2 * i]
			if position <= previous || position >= target || fuel < 1 || fuel > 2000 { return -2 }
			previous = position
		}

		mut heap := [8]i64{}
		mut heap_length := 0
		mut next_station := 0
		mut reach := start_fuel
		mut stops := i64(0)
		for reach < target {
			for next_station < count && input[3 + 2 * next_station] <= reach {
				mut child := heap_length
				heap_length += 1
				heap[child] = input[4 + 2 * next_station]
				for child > 0 {
					parent := (child - 1) / 2
					if heap[parent] >= heap[child] { break }
					temporary := heap[parent]
					heap[parent] = heap[child]
					heap[child] = temporary
					child = parent
				}
				next_station += 1
			}
			if heap_length == 0 { return -1 }
			maximum := heap[0]
			heap_length -= 1
			if heap_length > 0 {
				heap[0] = heap[heap_length]
				mut parent := 0
				for {
					left := 2 * parent + 1
					right := left + 1
					if left >= heap_length { break }
					mut child := left
					if right < heap_length && heap[right] > heap[left] { child = right }
					if heap[parent] >= heap[child] { break }
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
}
