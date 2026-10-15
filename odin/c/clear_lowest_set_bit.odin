package clear_lowest_set_bit

@(export)
clear_lowest_set_bit :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 2147483647 do return -1
	return value & (value - 1)
}
