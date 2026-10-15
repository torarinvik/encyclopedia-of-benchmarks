package longest_continuous_increasing_subsequence

import "core:c"

MAX_LENGTH :: 10_000

// Return the longest strictly increasing contiguous run.
@(export)
longest_continuous_increasing_subsequence :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < -1_000_000 || values[index] > 1_000_000 do return -1
	}
	if length == 0 do return 0

	current := i64(1)
	best := i64(1)
	for index := c.size_t(1); index < length; index += 1 {
		if values[index] > values[index-1] { current += 1 }
		else { current = 1 }
		if current > best do best = current
	}
	return best
}
