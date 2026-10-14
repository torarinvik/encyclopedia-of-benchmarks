package tim_sort

import "core:c"

TIM_SORT_RUN :: c.size_t(32)

insertion_sort_run :: proc(values: [^]i64, low, high: c.size_t) {
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

merge_runs :: proc(values, scratch: [^]i64, left, middle, right: c.size_t) {
	for index := left; index < right; index += 1 {
		scratch[index] = values[index]
	}
	first := left
	second := middle
	for output := left; output < right; output += 1 {
		if first == middle {
			values[output] = scratch[second]
			second += 1
		} else if second == right || scratch[first] <= scratch[second] {
			values[output] = scratch[first]
			first += 1
		} else {
			values[output] = scratch[second]
			second += 1
		}
	}
}

@(export)
tim_sort :: proc "c" (values, scratch: [^]i64, length: c.size_t) {
	if length < 2 { return }
	start := c.size_t(0)
	for start < length {
		remaining := length - start
		ending := if remaining < TIM_SORT_RUN then length else start + TIM_SORT_RUN
		insertion_sort_run(values, start, ending)
		start = ending
	}

	width := TIM_SORT_RUN
	for width < length {
		left := c.size_t(0)
		for left < length {
			left_remaining := length - left
			middle := left + (if width < left_remaining then width else left_remaining)
			right_remaining := length - middle
			right := middle + (if width < right_remaining then width else right_remaining)
			if middle < right {
				merge_runs(values, scratch, left, middle, right)
			}
			left = right
		}
		if width >= length - width { break }
		width *= 2
	}
}
