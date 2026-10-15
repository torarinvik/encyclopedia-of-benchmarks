module count_leading_zeros

@[export: 'count_leading_zeros']
pub fn count_leading_zeros(value i64) i64 {
	if value < -2147483648 || value > 2147483647 { return -1 }
	if value == 0 { return 32 }
	mut mask := i64(1) << 31
	mut count := i64(0)
	for (mask & value) == 0 {
		count++
		mask >>= 1
	}
	return count
}
