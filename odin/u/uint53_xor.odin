package uint53_xor

MAX_UINT53 :: i64(9_007_199_254_740_991)

// Iterative bitwise XOR for two nonnegative uint53 operands.
@(export)
uint53_xor :: proc "c" (left_input: i64, right_input: i64) -> i64 {
	if left_input < 0 || left_input > MAX_UINT53 || right_input < 0 || right_input > MAX_UINT53 do return -1
	left, right := left_input, right_input
	result := i64(0)
	bit := i64(1)
	for left != 0 && right != 0 {
		left_bit, right_bit := left % 2, right % 2
		result += ((left_bit + right_bit) % 2) * bit
		left = (left - left_bit) / 2
		right = (right - right_bit) / 2
		bit *= 2
	}
	return result + (left + right) * bit
}
