package subset_sum_count

import "core:c"

// Count indexed signed subsets that reach the requested sum.
@(export)
subset_sum_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 25 do return -1
	target := input[0]
	if target < -6144 || target > 6144 do return -1
	for index: c.size_t = 1; index < length; index += 1 {
		if input[index] < -256 || input[index] > 256 do return -1
	}
	ways: [12289]i64
	ways[6144] = 1
	low, high: i64 = 0, 0
	for index: c.size_t = 1; index < length; index += 1 {
		value := input[index]
		if value > 0 {
			for sum := high; sum >= low; sum -= 1 {
				ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
			}
			high += value
		} else if value < 0 {
			for sum := low; sum <= high; sum += 1 {
				ways[int(sum + value + 6144)] += ways[int(sum + 6144)]
			}
			low += value
		} else {
			for sum := low; sum <= high; sum += 1 { ways[int(sum + 6144)] *= 2 }
		}
	}
	return ways[int(target + 6144)]
}
