package lowest_set_bit

@(export)
lowest_set_bit :: proc "c" (value: i64) -> i64 {
	if value < 0 || value > 2_147_483_647 {
		return -1
	}
	return value & -value
}
