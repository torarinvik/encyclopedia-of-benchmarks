package uint53_bitwise_not

MAX_UINT53 :: i64(9_007_199_254_740_991)
TWO_TO_53 :: i64(9_007_199_254_740_992)

// Complement every bit in the fixed-width unsigned 53-bit domain.
@(export)
uint53_bitwise_not :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_UINT53 do return -1

	current := n
	result: i64 = 0
	bit: i64 = 1
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
	return TWO_TO_53 - bit + result
}
