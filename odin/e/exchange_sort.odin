package exchange_sort

import "core:c"

// In-place exchange sort for the shared sorting contract.
@(export)
exchange_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 { return }
	last := length - 1
	for first := c.size_t(0); first < last; first += 1 {
		for other := first + 1; other < length; other += 1 {
			if values[other] < values[first] {
				temporary := values[first]
				values[first] = values[other]
				values[other] = temporary
			}
		}
	}
}
