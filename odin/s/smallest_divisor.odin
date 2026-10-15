package smallest_divisor

import "core:c"

// Find the least positive divisor whose rounded sum fits the threshold.
@(export)
smallest_divisor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 257 do return -1
	threshold := input[0]
	if threshold < 1 || threshold > 1_000_000 do return -1
	maximum := i64(0)
	for index := 1; index < int(length); index += 1 {
		value := input[index]
		if value < 1 || value > 1_000_000 do return -1
		if value > maximum do maximum = value
	}
	count := i64(length - 1)
	if threshold < count do return -1
	low := i64(1)
	high := maximum
	for low < high {
		middle := low + (high - low) / 2
		sum := i64(0)
		for index := 1; index < int(length); index += 1 {
			sum += (input[index] + middle - 1) / middle
		}
		if sum <= threshold {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return low
}
