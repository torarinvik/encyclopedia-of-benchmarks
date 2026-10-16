package fast_searcher

import "core:c"

MAX_ARRAY_LENGTH :: 64
MAX_INPUT_LENGTH :: 67

search_segment :: proc "contextless" (input: [^]i64, begin, length: int,
		target: i64, offset: int) -> i64 {
	if length == 0 { return -1 }
	first := input[begin]
	last := input[begin + length - 1]
	if target < first || target > last { return -1 }
	if first == last { return if target == first then i64(offset) else -1 }

	interpolation := (length - 1) * int(target - first) / int(last - first)
	middle := length / 2
	left := min(interpolation, middle)
	right := max(interpolation, middle)
	from, to: int
	if target < input[begin + left] {
		if left == 0 { return -1 }
		from = 0
		to = left - 1
	} else if target < input[begin + right] {
		from = left
		to = right - 1
	} else {
		from = right
		to = length - 1
	}
	if to < from { return -1 }
	return search_segment(input, begin + from, to - from + 1, target, offset + from)
}

@(export)
fast_searcher :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -2
	if input[0] < 0 || input[0] > MAX_ARRAY_LENGTH do return -2
	count := int(input[0])
	if length != c.size_t(count + 2) do return -2
	for index := 0; index < count; index += 1 {
		value := input[1 + index]
		if value < -1000 || value > 1000 do return -2
		if index > 0 && input[index] >= value do return -2
	}
	target := input[int(length) - 1]
	if target < -1000 || target > 1000 do return -2
	return search_segment(input, 1, count, target, 0)
}
