module find_kth_number

const invalid_result = i64(-9223372036854775807 - 1)
const max_values = 1024

@[export: 'find_kth_number']
pub fn find_kth_number(values &i64, length usize) i64 {
	if length < 2 || length > max_values + 1 { return invalid_result }
	unsafe {
		k := values[0]
		count := int(length) - 1
		if k < 1 || k > count { return invalid_result }
		mut heap := [max_values]i32{}
		for i in 0 .. count {
			input := values[i + 1]
			if input < -2147483648 || input > 2147483647 { return invalid_result }
			mut index := i
			heap[index] = i32(input)
			for index > 0 {
				parent := (index - 1) / 2
				if heap[parent] >= heap[index] { break }
				heap[parent], heap[index] = heap[index], heap[parent]
				index = parent
			}
		}
		mut heap_size := count
		for removed in 1 .. int(k) {
			heap_size--
			heap[0] = heap[heap_size]
			mut index := 0
			for index * 2 + 1 < heap_size {
				mut child := index * 2 + 1
				if child + 1 < heap_size && heap[child + 1] > heap[child] { child++ }
				if heap[index] >= heap[child] { break }
				heap[index], heap[child] = heap[child], heap[index]
				index = child
			}
		}
		return heap[0]
	}
}
