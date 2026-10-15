module is_odd

// Return 1 for odd and 0 for even signed 64-bit integers.
@[export: 'is_odd']
pub fn is_odd(value i64) i64 {
	if value % 2 != 0 {
		return 1
	}
	return 0
}
