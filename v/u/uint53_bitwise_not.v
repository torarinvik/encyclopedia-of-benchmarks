module uint53_bitwise_not

const max_uint53 = i64(9007199254740991)
const two_to_53 = i64(9007199254740992)

// Complement every bit in the fixed-width unsigned 53-bit domain.
@[export: 'uint53_bitwise_not']
pub fn uint53_bitwise_not(n i64) i64 {
	if n < 0 || n > max_uint53 { return -1 }

	mut current := n
	mut result := i64(0)
	mut bit := i64(1)
	for current >= 255 {
		byte := current % 256
		result += (255 - byte) * bit
		current = (current - byte) / 256
		bit *= 256
	}
	for current != 0 {
		n_bit := current % 2
		result += (1 - n_bit) * bit
		current = (current - n_bit) / 2
		bit *= 2
	}
	return two_to_53 - bit + result
}
