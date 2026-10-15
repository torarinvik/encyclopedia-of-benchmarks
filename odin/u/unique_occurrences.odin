package unique_occurrences

import "core:c"

// Check whether every present value has a distinct occurrence count.
@(export)
unique_occurrences :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 1000 do return -1
	counts: [2001]i64 = {}
	seen_frequencies: [1001]bool = {}
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < -1000 || value > 1000 do return -1
		counts[int(value + 1000)] += 1
	}
	for frequency in counts {
		if frequency == 0 do continue
		if seen_frequencies[int(frequency)] do return 0
		seen_frequencies[int(frequency)] = true
	}
	return 1
}
