package merge_sort_nr

import "core:c"

MAX_VALUES :: 1024

@(export)
merge_sort_nr :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > c.size_t(MAX_VALUES) {
		return
	}
	n := int(length)
	scratch: [MAX_VALUES]i64
	width := 1
	for width < n {
		start := 0
		for start < n {
			middle := start + width
			if middle > n {
				middle = n
			}
			end_index := middle + width
			if end_index > n {
				end_index = n
			}
			left := start
			right := middle
			output := start
			for left < middle && right < end_index {
				if values[left] <= values[right] {
					scratch[output] = values[left]
					left += 1
				} else {
					scratch[output] = values[right]
					right += 1
				}
				output += 1
			}
			for left < middle {
				scratch[output] = values[left]
				left += 1
				output += 1
			}
			for right < end_index {
				scratch[output] = values[right]
				right += 1
				output += 1
			}
			start += width * 2
		}
		for index := 0; index < n; index += 1 {
			values[index] = scratch[index]
		}
		width *= 2
	}
}
