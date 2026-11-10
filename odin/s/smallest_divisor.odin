package smallest_divisor

import "core:c"

// Find the least positive divisor whose rounded sum fits the threshold.
@(export)
smallest_divisor :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 257 do return -1
	count := u64(length - 1)
	threshold := u64(input[0])
	if threshold < count || threshold > 1_000_000 do return -1
	maximum := u64(0)
	total := u64(0)
	for index := 1; index < int(length); index += 1 {
		value := u64(input[index])
		if value == 0 || value > 1_000_000 do return -1
		maximum = max(maximum, value)
		total += value
	}
	if threshold == count do return i64(maximum)

	low := (total - 1) / threshold + 1
	upper_bound := (total - count) / (threshold - count + 1) + 1
	high := min(maximum, upper_bound)
	for low < high {
		middle := low + ((high - low) >> 1)
		rounded_sum := count
		if count <= 4 {
			for index := 1; index < int(length); index += 1 {
				rounded_sum += u64((u32(input[index]) - 1) / u32(middle))
			}
		} else {
			reciprocal := (1_099_511_627_775 / middle) + 1
			for index := 1; index < int(length); index += 1 {
				rounded_sum += ((u64(input[index]) - 1) * reciprocal) >> 40
			}
		}
		if rounded_sum <= threshold { high = middle } else { low = middle + 1 }
	}
	return i64(low)
}
