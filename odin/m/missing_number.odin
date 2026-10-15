package missing_number

import "core:c"

MAX_VALUES :: 1024

// Return the absent value from 0 through the number of supplied values.
@(export)
missing_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_VALUES) || (length != 0 && values == nil) do return -1
	seen: [MAX_VALUES + 1]bool
	actual_sum := i64(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 0 || value > i64(length) do return -1
		if seen[int(value)] do return -1
		seen[int(value)] = true
		actual_sum += value
	}
	n := i64(length)
	return n * (n + 1) / 2 - actual_sum
}
