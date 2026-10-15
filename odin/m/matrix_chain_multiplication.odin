package matrix_chain_multiplication

import "core:c"

MAX_DIMS :: 65
MAX_DIMENSION :: i64(1000)
MAX_CELLS :: MAX_DIMS * MAX_DIMS

@(export)
matrix_chain_multiplication :: proc "c" (dimensions: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_DIMS) do return -1
	for index := 0; index < int(length); index += 1 {
		if dimensions[index] < 1 || dimensions[index] > MAX_DIMENSION do return -1
	}
	if length < 2 do return 0

	matrix_count := int(length) - 1
	costs: [MAX_CELLS]i64
	for index := 0; index < MAX_CELLS; index += 1 { costs[index] = 0 }
	for chain_length := 2; chain_length <= matrix_count; chain_length += 1 {
		for start := 0; start + chain_length <= matrix_count; start += 1 {
			finish := start + chain_length - 1
			best := i64(9223372036854775807)
			for split := start; split < finish; split += 1 {
				cost := costs[start * MAX_DIMS + split] + costs[(split + 1) * MAX_DIMS + finish] + dimensions[start] * dimensions[split + 1] * dimensions[finish + 1]
				if cost < best do best = cost
			}
			costs[start * MAX_DIMS + finish] = best
		}
	}
	return costs[matrix_count - 1]
}
