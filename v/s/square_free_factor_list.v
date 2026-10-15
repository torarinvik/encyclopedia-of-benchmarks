module square_free_factor_list

// Check that an integer factor list has no repeated values.
@[export: 'square_free_factor_list']
pub fn square_free_factor_list(values &i64, length usize) i64 {
	if length > 256 { return -1 }
	unsafe {
		for i := usize(0); i < length; i++ {
			if values[i] < -2_147_483_648 || values[i] > 2_147_483_647 { return -1 }
			for j := usize(0); j < i; j++ {
				if values[i] == values[j] { return 0 }
			}
		}
	}
	return 1
}
