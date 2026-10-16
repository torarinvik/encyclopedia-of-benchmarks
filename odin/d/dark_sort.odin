package dark_sort

import "core:c"

@(export)
dark_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length < 2 { return }
	maximum := values[0]
	for i := c.size_t(1); i < length; i += 1 {
		if values[i] > maximum { maximum = values[i] }
	}
	counts: [129]i64
	for i := c.size_t(0); i < length; i += 1 { counts[values[i]] += 1 }
	output := c.size_t(0)
	for value := i64(0); value <= maximum; value += 1 {
		for counts[value] > 0 {
			values[output] = value
			output += 1
			counts[value] -= 1
		}
	}
}
