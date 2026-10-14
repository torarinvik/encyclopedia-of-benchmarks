package selection_sort_recursive

import "core:c"

minimum_index :: proc(values: [^]i64, start, end: c.size_t) -> c.size_t {
	if start + 1 >= end { return start }
	minimum := minimum_index(values, start + 1, end)
	if values[start] < values[minimum] { return start }
	return minimum
}

selection_sort_range :: proc(values: [^]i64, start, length: c.size_t) {
	if start + 1 >= length { return }
	minimum := minimum_index(values, start, length)
	if minimum != start {
		temporary := values[start]
		values[start] = values[minimum]
		values[minimum] = temporary
	}
	selection_sort_range(values, start + 1, length)
}

@(export)
selection_sort_recursive :: proc "c" (values: [^]i64, length: c.size_t) {
	selection_sort_range(values, 0, length)
}
