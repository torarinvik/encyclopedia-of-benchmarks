package slow_sort

import "core:c"

slow_sort_range :: proc "contextless" (values: [^]i64, first, last: int) {
	if first >= last do return
	middle := first + (last - first) / 2
	slow_sort_range(values, first, middle)
	slow_sort_range(values, middle + 1, last)
	if values[last] < values[middle] {
		temporary := values[last]; values[last] = values[middle]; values[middle] = temporary
	}
	slow_sort_range(values, first, last - 1)
}

@(export)
slow_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > 1 do slow_sort_range(values, 0, int(length) - 1)
}
