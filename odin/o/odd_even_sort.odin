package odd_even_sort

import "core:c"

// Stable odd-even transposition sort for the shared sorting contract.
@(export)
odd_even_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 {
		return
	}
	swapped := true
	for swapped {
		swapped = false
		for index := c.size_t(0); index + 1 < length; index += 2 {
			if values[index] > values[index + 1] {
				temporary := values[index]
				values[index] = values[index + 1]
				values[index + 1] = temporary
				swapped = true
			}
		}
		for index := c.size_t(1); index + 1 < length; index += 2 {
			if values[index] > values[index + 1] {
				temporary := values[index]
				values[index] = values[index + 1]
				values[index + 1] = temporary
				swapped = true
			}
		}
	}
}
