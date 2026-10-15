package uint53_bitwise_xor

MAX_UINT53 :: u64(9_007_199_254_740_991)
INVALID_RESULT :: i64 = -1

// XOR two values in the bounded unsigned 53-bit domain.
@(export)
uint53_bitwise_xor :: proc "c" (n, m: u64) -> i64 {
	if n > MAX_UINT53 || m > MAX_UINT53 do return INVALID_RESULT

	current_n := n
	current_m := m
	result: u64 = 0
	bit: u64 = 1
	for current_n != 0 && current_m != 0 {
		n_bit := current_n % 2
		m_bit := current_m % 2
		result += ((n_bit + m_bit) % 2) * bit
		current_n = (current_n - n_bit) / 2
		current_m = (current_m - m_bit) / 2
		bit *= 2
	}
	return i64(result + (current_n + current_m) * bit)
}
