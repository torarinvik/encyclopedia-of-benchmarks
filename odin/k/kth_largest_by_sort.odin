package kth_largest_by_sort

import "core:c"

MAX_LENGTH :: 512

// Restore the max-heap property in values[root:end].
sift_down :: proc "c" (values: [^]i32, root_start, end: int) {
	root := root_start
	for root < end / 2 {
		child := root * 2 + 1
		if child + 1 < end && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

// Sort a local copy with portable heapsort, then index from the end.
@(export)
kth_largest_by_sort :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_LENGTH + 1 do return -1
	n := int(length) - 1
	if input[0] < 1 || input[0] > i64(n) do return -1
	values: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	for start := n / 2; start > 0; start -= 1 {
		sift_down(&values[0], start - 1, n)
	}
	end := n
	for end > 1 {
		temporary := values[0]
		values[0] = values[end - 1]
		values[end - 1] = temporary
		end -= 1
		sift_down(&values[0], 0, end)
	}
	return i64(values[n - int(input[0])])
}
