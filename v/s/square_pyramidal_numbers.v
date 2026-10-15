module square_pyramidal_numbers

// Exact square-pyramidal sum within the pinned u64 intermediate range.
@[export: 'square_pyramidal_numbers']
pub fn square_pyramidal_numbers(n i64) i64 {
	if n < 0 || n > 2_097_151 {
		return -1
	}
	value := u64(n)
	numerator := value * (value + 1) * (2 * value + 1)
	return i64(numerator / 6)
}
