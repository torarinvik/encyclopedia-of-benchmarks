module lowest_set_bit

// Return the isolated least significant set bit.
@[export: 'lowest_set_bit']
pub fn lowest_set_bit(value i64) i64 {
	if value < 0 || value > 2_147_483_647 {
		return -1
	}
	return value & -value
}
