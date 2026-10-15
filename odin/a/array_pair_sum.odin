package array_pair_sum

import "core:c"

MAX_LENGTH :: 4096

sift_down :: proc "c" (values: []i64, root_value: c.size_t, count: c.size_t) {
	root := root_value
	for root*2+1 < count {
		child := root*2 + 1
		if child+1 < count && values[child] < values[child+1] do child += 1
		if values[root] >= values[child] do return
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

// Sort signed 32-bit values and sum the first of every adjacent pair.
@(export)
array_pair_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || length % 2 != 0 || (length != 0 && input == nil) do return -1
	values: [MAX_LENGTH]i64 = {}
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
		values[index] = input[index]
	}
	for start := length / 2; start > 0; start -= 1 do sift_down(values[:length], start - 1, length)
	for ending := length; ending > 1; ending -= 1 {
		temporary := values[0]
		values[0] = values[ending-1]
		values[ending-1] = temporary
		sift_down(values[:ending-1], 0, ending-1)
	}
	total := i64(0)
	for index := c.size_t(0); index < length; index += 2 do total += values[index]
	return total
}
