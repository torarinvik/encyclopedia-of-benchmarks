package mex

import "core:c"

MAX_VALUES :: 100000

sift_down :: proc "contextless" (values: [^]i64, root_start, end: int) {
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

heap_sort :: proc "contextless" (values: [^]i64, length: int) {
	for start := length / 2; start > 0; start -= 1 {
		sift_down(values, start - 1, length)
	}
	for end := length; end > 1; end -= 1 {
		temporary := values[0]
		values[0] = values[end - 1]
		values[end - 1] = temporary
		sift_down(values, 0, end - 1)
	}
}

@(export)
mex :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_VALUES + 1 do return -1
	count_value := input[0]
	if count_value < 0 || count_value > MAX_VALUES || length != c.size_t(count_value) + 1 do return -1
	count := int(count_value)
	values: [MAX_VALUES]i64 = {}
	for index := 0; index < count; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = value
	}
	heap_sort(&values[0], count)
	candidate := i64(0)
	for index := 0; index < count; index += 1 {
		if values[index] == candidate do candidate += 1
	}
	return candidate
}
