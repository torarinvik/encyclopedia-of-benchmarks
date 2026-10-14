package cocktail_selection_sort

import "core:c"

MAX_VALUES :: 1024

@(export)
cocktail_selection_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length > c.size_t(MAX_VALUES) {
		return
	}
	low := 0
	high := int(length)
	for high-low > 1 {
		minimum_index := low
		maximum_index := low
		for index := low + 1; index < high; index += 1 {
			if values[index] < values[minimum_index] {
				minimum_index = index
			}
			if values[index] > values[maximum_index] {
				maximum_index = index
			}
		}
		minimum := values[minimum_index]
		values[minimum_index] = values[low]
		values[low] = minimum
		if maximum_index == low {
			maximum_index = minimum_index
		}
		maximum := values[maximum_index]
		values[maximum_index] = values[high-1]
		values[high-1] = maximum
		low += 1
		high -= 1
	}
}
