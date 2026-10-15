package contains_duplicate

import "core:c"

MAX_VALUES :: 1024

sift_down :: proc "contextless" (values: [^]i64, root_start, length: int) {
	root := root_start
	for root < length / 2 {
		child := root * 2 + 1
		if child + 1 < length && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
@(export)
contains_duplicate :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_VALUES) || (length != 0 && input == nil) do return -1
	values: [MAX_VALUES]i64
	count := int(length)
	for index := 0; index < count; index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = value
	}
	for start := count / 2; start > 0; start -= 1 {
		sift_down(&values[0], start - 1, count)
	}
	for ending := count; ending > 1; ending -= 1 {
		temporary := values[0]
		values[0] = values[ending - 1]
		values[ending - 1] = temporary
		sift_down(&values[0], 0, ending - 1)
	}
	for index := 1; index < count; index += 1 {
		if values[index - 1] == values[index] do return 1
	}
	return 0
}
