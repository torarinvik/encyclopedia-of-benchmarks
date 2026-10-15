module check_even

// Return 1 for even and 0 for odd signed 64-bit integers.
@[export: 'check_even']
pub fn check_even(value i64) i64 {
	if value % 2 == 0 {
		return 1
	}
	return 0
}
