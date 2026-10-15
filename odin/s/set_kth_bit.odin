package set_kth_bit

import "core:c"

@(export)
set_kth_bit :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	number, bit := input[0], input[1]
	if number < 0 || number > 2147483647 || bit < 0 || bit > 30 do return -1
	return number | (i64(1) << u64(bit))
}
