package heap_sort

import "core:c"

sift_down :: proc(values: [^]i64, root, end: c.size_t) {
	current := root
	for current < end / 2 {
		child := current * 2 + 1
		if child + 1 < end && values[child] < values[child + 1] {
			child += 1
		}
		if values[current] >= values[child] {
			break
		}
		temporary := values[current]
		values[current] = values[child]
		values[child] = temporary
		current = child
	}
}

@(export)
heap_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, length)
	}
	end := length
	for end > 1 {
		end -= 1
		temporary := values[0]
		values[0] = values[end]
		values[end] = temporary
		sift_down(values, 0, end)
	}
}
