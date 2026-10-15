module uint53_bitwise_xor

const max_uint53 = u64(9007199254740991)
const invalid_result = i64(-1)

// XOR two values in the bounded unsigned 53-bit domain.
@[export: 'uint53_bitwise_xor']
pub fn uint53_bitwise_xor(n u64, m u64) i64 {
	if n > max_uint53 || m > max_uint53 { return invalid_result }

	mut current_n := n
	mut current_m := m
	mut result := u64(0)
	mut bit := u64(1)
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
