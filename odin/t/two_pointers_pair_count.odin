package two_pointers_pair_count

import "core:c"

MAX_VALUES :: 256
MAX_INPUT_LENGTH :: 258

sift_down :: proc "contextless" (values: [^]i64, root_start, end_value: int) {
	root := root_start
	for root < end_value / 2 {
		child := root * 2 + 1
		if child + 1 < end_value && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

heap_sort_values :: proc "contextless" (values: [^]i64, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		sift_down(values, 0, ending)
	}
}

@(export)
two_pointers_pair_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	target, count_value := input[0], input[1]
	if count_value < 0 || count_value > MAX_VALUES do return -1
	count := int(count_value)
	if length != c.size_t(2 + count) || target < -2_000_000 || target > 2_000_000 do return -1

	values: [MAX_VALUES]i64
	for index := 0; index < count; index += 1 {
		value := input[2 + index]
		if value < -1_000_000 || value > 1_000_000 do return -1
		values[index] = value
	}
	heap_sort_values(&values[0], count)
  if count < 2 do return 0
	for index := 1; index < count; index += 1 {
		if values[index - 1] == values[index] do return -1
	}

	left, right := 0, count - 1
	pairs := i64(0)
	for left < right {
		sum := values[left] + values[right]
		if sum < target {
			left += 1
		} else if sum > target {
			right -= 1
		} else {
			pairs += 1
			left += 1
		}
	}
	return pairs
}

