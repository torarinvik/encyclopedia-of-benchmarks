package heap_sort_2

import "core:c"

MAX_VALUES :: 1024

sift_up :: proc "contextless" (values: [^]i64, index_value: int) {
	index := index_value
	for index > 0 {
		parent := (index - 1) / 2
		if values[parent] >= values[index] { break }
		temporary := values[parent]
		values[parent] = values[index]
		values[index] = temporary
		index = parent
	}
}

sift_down :: proc "contextless" (values: [^]i64, size: int) {
	root := 0
	for root < size / 2 {
		left := root * 2 + 1
		largest := left
		right := left + 1
		if right < size && values[right] > values[left] { largest = right }
		if values[root] >= values[largest] { break }
		temporary := values[root]
		values[root] = values[largest]
		values[largest] = temporary
		root = largest
	}
}

@(export)
heap_sort_2 :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > c.size_t(MAX_VALUES) { return }
	n := int(length)
	for index := 0; index < n; index += 1 { sift_up(values, index) }
	for size := n; size > 1; size -= 1 {
		temporary := values[0]
		values[0] = values[size-1]
		values[size-1] = temporary
		sift_down(values, size-1)
	}
}
