package three_sum_closest

import "core:c"

MAX_ITEMS :: 512
INVALID_RESULT :: i64(-9000000000000000000)

heap_sift_down :: proc "contextless" (values: [^]i64, root_start, end_value: int) {
	root := root_start
	for root < end_value / 2 {
		child := root * 2 + 1
		if child + 1 < end_value && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]; values[root] = values[child]; values[child] = temporary
		root = child
	}
}

heap_sort_values :: proc "contextless" (values: [^]i64, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		heap_sift_down(values, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		temporary := values[0]; values[0] = values[ending]; values[ending] = temporary
		heap_sift_down(values, 0, ending)
	}
}

abs_difference :: proc "contextless" (left, right: i64) -> i64 {
	difference := left - right
	if difference < 0 do return -difference
	return difference
}

@(export)
three_sum_closest :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > c.size_t(MAX_ITEMS + 2) do return INVALID_RESULT
	target := input[0]
	count_value := input[1]
	if target < -2147483648 || target > 2147483647 || count_value < 3 || count_value > MAX_ITEMS do return INVALID_RESULT
	count := int(count_value)
	if int(length) != count + 2 do return INVALID_RESULT
	values: [MAX_ITEMS]i64
	for index := 0; index < count; index += 1 {
		value := input[index + 2]
		if value < -2147483648 || value > 2147483647 do return INVALID_RESULT
		values[index] = value
	}
	heap_sort_values(&values[0], count)
	best := values[0] + values[1] + values[2]
	best_difference := abs_difference(target, best)
	for first := 0; first + 2 < count; first += 1 {
		left := first + 1
		right := count - 1
		for left < right {
			sum := values[first] + values[left] + values[right]
			difference := abs_difference(target, sum)
			if difference < best_difference || (difference == best_difference && sum < best) {
				best = sum
				best_difference = difference
			}
			if sum < target { left += 1 } else if sum > target { right -= 1 } else { return sum }
		}
	}
	return best
}
