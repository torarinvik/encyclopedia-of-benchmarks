package subset_sum_exists

import "core:c"

// Decide whether a signed integer subset reaches the requested sum.
@(export)
subset_sum_exists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 25 do return -1
	target := input[0]
	if target < -6144 || target > 6144 do return -1
	for index: c.size_t = 1; index < length; index += 1 {
		if input[index] < -256 || input[index] > 256 do return -1
	}
	reachable: [12289]bool
	reachable[6144] = true
	low, high: i64 = 0, 0
	for index: c.size_t = 1; index < length; index += 1 {
		value := input[index]
		if value > 0 {
			for sum := high; sum >= low; sum -= 1 {
				if reachable[int(sum + 6144)] do reachable[int(sum + value + 6144)] = true
			}
			high += value
		} else if value < 0 {
			for sum := low; sum <= high; sum += 1 {
				if reachable[int(sum + 6144)] do reachable[int(sum + value + 6144)] = true
			}
			low += value
		}
	}
	if reachable[int(target + 6144)] do return 1
	return 0
}
