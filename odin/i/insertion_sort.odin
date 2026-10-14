package insertion_sort

import "core:c"

// Stable insertion sort for the shared mutable in-place sorting contract.
@(export)
insertion_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	for index := c.size_t(1); index < length; index += 1 {
		key := values[index]
		position := index
		for position > 0 && values[position - 1] > key {
			values[position] = values[position - 1]
			position -= 1
		}
		values[position] = key
	}
}
