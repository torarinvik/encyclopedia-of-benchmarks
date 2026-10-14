package bubble_sort

import "core:c"

// Stable bubble sort for the shared mutable in-place sorting contract.
@(export)
bubble_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	for end_index := length; end_index > 1; end_index -= 1 {
		swapped := false
		for index := c.size_t(0); index + 1 < end_index; index += 1 {
			if values[index] > values[index + 1] {
				temporary := values[index]
				values[index] = values[index + 1]
				values[index + 1] = temporary
				swapped = true
			}
		}
		if !swapped {
			break
		}
	}
}
