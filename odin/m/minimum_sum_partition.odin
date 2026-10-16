package minimum_sum_partition

import "core:c"

MAX_VALID_INPUT_LENGTH :: 64
MAX_TOTAL_SUM :: 4096

@(export)
minimum_sum_partition :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_VALID_INPUT_LENGTH || (input == nil && length != 0) do return -1

	total: i64 = 0
	for index: c.size_t = 0; index < length; index += 1 {
		value := input[index]
		if value < 0 || value > MAX_TOTAL_SUM || total > MAX_TOTAL_SUM - value do return -1
		total += value
	}

	target := int(total / 2)
	reachable: [MAX_TOTAL_SUM / 2 + 1]bool
	reachable[0] = true
	closest := 0
	for index: c.size_t = 0; index < length; index += 1 {
		value := int(input[index])
		for sum := target; sum > 0; sum -= 1 {
			if value <= sum && reachable[sum - value] do reachable[sum] = true
			if reachable[sum] && sum > closest do closest = sum
		}
	}
	return total - 2 * i64(closest)
}
