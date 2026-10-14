package bitonic_sort

import "core:c"

bitonic_compare :: proc(values: [^]i64, left, right: c.size_t, ascending: bool) {
	if (ascending && values[left] > values[right]) || (!ascending && values[left] < values[right]) {
		temporary := values[left]
		values[left] = values[right]
		values[right] = temporary
	}
}

bitonic_merge :: proc(values: [^]i64, low, length: c.size_t, ascending: bool) {
	if length < 2 {
		return
	}
	half := length / 2
	for index := low; index < low + half; index += 1 {
		bitonic_compare(values, index, index + half, ascending)
	}
	bitonic_merge(values, low, half, ascending)
	bitonic_merge(values, low + half, half, ascending)
}

bitonic_sort_range :: proc(values: [^]i64, low, length: c.size_t, ascending: bool) {
	if length < 2 {
		return
	}
	half := length / 2
	bitonic_sort_range(values, low, half, true)
	bitonic_sort_range(values, low + half, half, false)
	bitonic_merge(values, low, length, ascending)
}

@(export)
bitonic_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	bitonic_sort_range(values, 0, length, true)
}
