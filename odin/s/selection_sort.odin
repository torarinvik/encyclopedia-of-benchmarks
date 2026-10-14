package selection_sort

import "core:c"

// In-place selection sort for the shared sorting contract.
@(export)
selection_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	for index := c.size_t(0); index + 1 < length; index += 1 {
		minimum := index
		for probe := index + 1; probe < length; probe += 1 {
			if values[probe] < values[minimum] {
				minimum = probe
			}
		}
		if minimum != index {
			temporary := values[index]
			values[index] = values[minimum]
			values[minimum] = temporary
		}
	}
}
