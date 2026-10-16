package kth_element_finder

import "core:c"

INVALID_RESULT :: i64(-9223372036854775807) - 1

sift_down :: proc(heap: []i64, root0: int, min_heap: bool) {
	root := root0
	for {
		best := root
		left := root * 2 + 1
		right := left + 1
		if left < len(heap) {
			if (min_heap && heap[left] < heap[best]) || (!min_heap && heap[left] > heap[best]) { best = left }
		}
		if right < len(heap) {
			if (min_heap && heap[right] < heap[best]) || (!min_heap && heap[right] > heap[best]) { best = right }
		}
		if best == root { break }
		heap[root], heap[best] = heap[best], heap[root]
		root = best
	}
}

@(export)
kth_element_finder :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 259 { return INVALID_RESULT }
	mode := input[0]
	n_value := input[1]
	k_value := input[2]
	if (mode != 0 && mode != 1) || n_value < 1 || n_value > 256 || k_value < 1 || k_value > n_value {
		return INVALID_RESULT
	}
	n := int(n_value)
	k := int(k_value)
	if length != c.size_t(n + 3) { return INVALID_RESULT }
	for i := 0; i < n; i += 1 {
		if input[i + 3] < -1_000_000 || input[i + 3] > 1_000_000 { return INVALID_RESULT }
	}

	min_heap := mode == 0
	var heap: [256]i64
	for i := 0; i < k; i += 1 { heap[i] = input[i + 3] }
	start := k / 2
	for start > 0 {
		start -= 1
		sift_down(heap[:k], start, min_heap)
	}
	for i := k; i < n; i += 1 {
		value := input[i + 3]
		if (min_heap && value > heap[0]) || (!min_heap && value < heap[0]) {
			heap[0] = value
			sift_down(heap[:k], 0, min_heap)
		}
	}
	return heap[0]
}
