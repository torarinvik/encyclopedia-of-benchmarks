package clear_leftmost_set_bit

@(export)
clear_leftmost_set_bit :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 2147483647 do return -1
	if value == 0 do return 0
	temp := value
	position := i64(0)
	for temp > 0 {
		temp >>= 1
		position += 1
	}
	mask := ~(i64(1) << (position - 1))
	return value & mask
}
