package ways_to_split_array

import "core:c"

MAX_LENGTH :: 100_000
MAX_VALUE :: i64(100_000)

// Count positions where the prefix sum is at least the remaining suffix sum.
@(export)
ways_to_split_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > MAX_LENGTH do return -1
	n := int(length)
	total := u64(0)
	largest_biased_value := u64(0)
	for index := 0; index < n; index += 1 {
		value := u64(values[index])
		largest_biased_value = max(largest_biased_value, value + u64(MAX_VALUE))
		total += value
	}
	if largest_biased_value > 2 * u64(MAX_VALUE) do return -1
	threshold := i64(total + 1) >> 1
	prefix := u64(0)
	ways := i64(0)
	for index := 0; index < n - 1; index += 1 {
		prefix += u64(values[index])
		if i64(prefix) >= threshold do ways += 1
	}
	return ways
}
