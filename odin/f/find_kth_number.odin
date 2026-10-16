package find_kth_number

import "core:c"

INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
MAX_VALUES :: int = 1024

@(export)
find_kth_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_VALUES + 1) do return INVALID_RESULT
	k := values[0]
	count := int(length) - 1
	if k < 1 || k > i64(count) do return INVALID_RESULT
	heap: [MAX_VALUES]i32
	for i := 0; i < count; i += 1 {
		input := values[i + 1]
		if input < -2_147_483_648 || input > 2_147_483_647 do return INVALID_RESULT
		index := i
		heap[index] = i32(input)
		for index > 0 {
			parent := (index - 1) / 2
			if heap[parent] >= heap[index] do break
			heap[parent], heap[index] = heap[index], heap[parent]
			index = parent
		}
	}
	heap_size := count
	for removed := i64(1); removed < k; removed += 1 {
		heap_size -= 1
		heap[0] = heap[heap_size]
		index := 0
		for index * 2 + 1 < heap_size {
			child := index * 2 + 1
			if child + 1 < heap_size && heap[child + 1] > heap[child] do child += 1
			if heap[index] >= heap[child] do break
			heap[index], heap[child] = heap[child], heap[index]
			index = child
		}
	}
	return i64(heap[0])
}
