package recursive_bubble_sort

import "core:c"

recursive_bubble_sort_range :: proc(values: [^]i64, length: c.size_t) {
	if length < 2 { return }
	for index := c.size_t(0); index + 1 < length; index += 1 {
		if values[index] > values[index + 1] {
			temporary := values[index]
			values[index] = values[index + 1]
			values[index + 1] = temporary
		}
	}
	recursive_bubble_sort_range(values, length - 1)
}

@(export)
recursive_bubble_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	recursive_bubble_sort_range(values, length)
}
