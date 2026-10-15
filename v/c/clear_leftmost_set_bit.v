module clear_leftmost_set_bit

@[export: 'clear_leftmost_set_bit']
pub fn clear_leftmost_set_bit(value i64) i64 {
	if value < 0 || value > 2147483647 { return -1 }
	if value == 0 { return 0 }
	mut temp := value
	mut position := i64(0)
	for temp > 0 {
		temp >>= 1
		position++
	}
	mask := ~(i64(1) << (position - 1))
	return value & mask
}
