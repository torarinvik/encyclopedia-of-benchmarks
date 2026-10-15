module rightmost_set_bit

// Return the one-based position of the least significant set bit.
@[export: 'rightmost_set_bit']
pub fn rightmost_set_bit(value i64) i64 {
	if value <= 0 || value > 2_147_483_647 {
		return -1
	}
	mut lowest := u32(value) & (u32(0) - u32(value))
	mut position := i64(1)
	for (lowest & 1) == 0 {
		lowest >>= 1
		position++
	}
	return position
}
