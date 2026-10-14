package intro_sort

import "core:c"

swap_i64 :: proc(values: [^]i64, left, right: c.size_t) {
	temporary := values[left]
	values[left] = values[right]
	values[right] = temporary
}

insertion_sort_range :: proc(values: [^]i64, low, high: c.size_t) {
	for index := low + 1; index < high; index += 1 {
		key := values[index]
		cursor := index
		for cursor > low && values[cursor - 1] > key {
			values[cursor] = values[cursor - 1]
			cursor -= 1
		}
		values[cursor] = key
	}
}

sift_down :: proc(values: [^]i64, start, count, root_start: c.size_t) {
	root := root_start
	for root < count / 2 {
		child := root * 2 + 1
		if child + 1 < count && values[start + child] < values[start + child + 1] {
			child += 1
		}
		if values[start + root] >= values[start + child] { return }
		swap_i64(values, start + root, start + child)
		root = child
	}
}

heap_sort_range :: proc(values: [^]i64, low, count: c.size_t) {
	for parent := count / 2; parent > 0; {
		parent -= 1
		sift_down(values, low, count, parent)
	}
	for ending := count; ending > 1; {
		ending -= 1
		swap_i64(values, low, low + ending)
		sift_down(values, low, ending, 0)
	}
}

partition_range :: proc(values: [^]i64, low, high: c.size_t) -> c.size_t {
	last := high - 1
	pivot_index := low + (high - low) / 2
	swap_i64(values, pivot_index, last)
	pivot := values[last]
	boundary := low
	for probe := low; probe < last; probe += 1 {
		if values[probe] <= pivot {
			swap_i64(values, boundary, probe)
			boundary += 1
		}
	}
	swap_i64(values, boundary, last)
	return boundary
}

intro_sort_range :: proc(values: [^]i64, low, high, depth: c.size_t) {
	count := high - low
	if count <= 16 {
		insertion_sort_range(values, low, high)
		return
	}
	if depth == 0 {
		heap_sort_range(values, low, count)
		return
	}
	pivot := partition_range(values, low, high)
	intro_sort_range(values, low, pivot, depth - 1)
	intro_sort_range(values, pivot + 1, high, depth - 1)
}

depth_limit :: proc(length: c.size_t) -> c.size_t {
	remaining := length
	logarithm := c.size_t(0)
	for remaining > 1 {
		remaining /= 2
		logarithm += 1
	}
	return logarithm * 2
}

// Introsort with quicksort partitioning, a heapsort depth fallback, and insertion cutoff.
@(export)
intro_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 { return }
	intro_sort_range(values, 0, length, depth_limit(length))
}
