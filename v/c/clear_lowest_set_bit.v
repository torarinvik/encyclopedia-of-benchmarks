module clear_lowest_set_bit

@[export: 'clear_lowest_set_bit']
pub fn clear_lowest_set_bit(value i64) i64 {
	if value < 0 || value > 2147483647 { return -1 }
	return value & (value - 1)
}
