package uint53_bitwise_or

// Bitwise inclusive OR over the Lua uint53 domain.
@(export)
uint53_bitwise_or :: proc "c" (left, right: u64) -> i64 {
	max_uint53 := u64(9_007_199_254_740_991)
	if left > max_uint53 || right > max_uint53 do return -1
	n, m := left, right
	result, bit := u64(0), u64(1)
	for n != 0 && m != 0 {
		n_bit, m_bit := n % 2, m % 2
		result += (1 - (1 - n_bit) * (1 - m_bit)) * bit
		n = (n - n_bit) / 2
		m = (m - m_bit) / 2
		bit *= 2
	}
	return i64(result + (n + m) * bit)
}
