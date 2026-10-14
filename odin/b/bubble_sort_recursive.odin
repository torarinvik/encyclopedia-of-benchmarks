package bubble_sort_recursive

import "core:c"

MAX_VALUES :: 256

bubble_sort_recursive_impl :: proc "contextless" (values: [^]i64, length: int) {
	if length <= 1 {
		return
	}
	swapped := false
	for index := 0; index + 1 < length; index += 1 {
		if values[index] > values[index+1] {
			temporary := values[index]
			values[index] = values[index+1]
			values[index+1] = temporary
			swapped = true
		}
	}
	if swapped {
		bubble_sort_recursive_impl(values, length-1)
	}
}

@(export)
bubble_sort_recursive :: proc "c" (values: [^]i64, length: c.size_t) {
	if length <= c.size_t(MAX_VALUES) {
		bubble_sort_recursive_impl(values, int(length))
	}
}
