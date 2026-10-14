package jump_search

import "core:c"

integer_sqrt :: proc(value: c.size_t) -> c.size_t {
	if value < 2 do return value
	low := c.size_t(1)
	high := value / 2 + 1
	result := c.size_t(1)
	for low <= high {
		middle := low + (high - low) / 2
		if middle <= value / middle {
			result = middle
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return result
}

// Jump search in an ascending sequence for the shared benchmark contract.
@(export)
jump_search :: proc "c" (values: [^]i64, length: c.size_t, target: i64) -> i64 {
	if length == 0 do return -1
	step := integer_sqrt(length)
	block_start := c.size_t(0)
	block_end := min(step, length)
	for values[block_end - 1] < target {
		if block_end == length do return -1
		block_start = block_end
		block_end = if step > length - block_end then length else block_end + step
	}
	for index := block_start; index < block_end; index += 1 {
		if values[index] == target do return i64(index)
		if values[index] > target do return -1
	}
	return -1
}
