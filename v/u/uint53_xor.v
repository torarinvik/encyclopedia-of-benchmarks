module uint53_xor

const max_uint53 = i64(9_007_199_254_740_991)

// Iterative bitwise XOR for two nonnegative uint53 operands.
@[export: 'uint53_xor']
pub fn uint53_xor(left_input i64, right_input i64) i64 {
	if left_input < 0 || left_input > max_uint53 || right_input < 0 || right_input > max_uint53 { return -1 }
	mut left := left_input
	mut right := right_input
	mut result := i64(0)
	mut bit := i64(1)
	for left != 0 && right != 0 {
		left_bit := left % 2
		right_bit := right % 2
		result += ((left_bit + right_bit) % 2) * bit
		left = (left - left_bit) / 2
		right = (right - right_bit) / 2
		bit *= 2
	}
	return result + (left + right) * bit
}
