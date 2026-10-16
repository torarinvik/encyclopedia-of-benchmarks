package bst_from_sorted_array

import "core:c"

bst_shape :: proc "contextless" (start, ending, heap_index: int) -> u64 {
	if start >= ending do return 0
	middle := start + (ending - start - 1) / 2
	return (u64(1) << u64(heap_index)) |
		bst_shape(start, middle, 2 * heap_index + 1) |
		bst_shape(middle + 1, ending, 2 * heap_index + 2)
}

@(export)
bst_from_sorted_array :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > 15 do return -1
	for index: c.size_t = 0; index < length; index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 do return -1
		if index > 0 && input[index - 1] >= value do return -1
	}
	return i64(bst_shape(0, int(length), 0))
}
