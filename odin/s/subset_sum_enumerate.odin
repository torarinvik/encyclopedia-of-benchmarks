package subset_sum_enumerate

import "core:c"

// Emit the index masks of all signed subsets matching the target.
@(export)
subset_sum_enumerate :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > 9 do return -1
	target := input[0]
	if target < -512 || target > 512 do return -1
	items := length - 1
	for index: c.size_t = 0; index < items; index += 1 {
		if input[index + 1] < -64 || input[index + 1] > 64 do return -1
	}
	masks: [256]u8
	count: c.size_t = 0
	limit := c.size_t(1) << items
	for mask: c.size_t = 0; mask < limit; mask += 1 {
		sum: i64 = 0
		for index: c.size_t = 0; index < items; index += 1 {
			if (mask / (c.size_t(1) << index)) % 2 == 1 { sum += input[index + 1] }
		}
		if sum == target {
			masks[count] = u8(mask)
			count += 1
		}
	}
	if output_capacity < count do return -2
	for index: c.size_t = 0; index < count; index += 1 { output[index] = masks[index] }
	return i64(count)
}
