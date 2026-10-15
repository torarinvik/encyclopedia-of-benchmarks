package rightmost_set_bit

@(export)
rightmost_set_bit :: proc "c" (value: i64) -> i64 {
	if value <= 0 || value > 2_147_483_647 {
		return -1
	}
	lowest := u32(value) & (0 - u32(value))
	position: i64 = 1
	for (lowest & 1) == 0 {
		lowest >>= 1
		position += 1
	}
	return position
}
