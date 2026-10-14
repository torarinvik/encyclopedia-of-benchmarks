package lcm

// Portable LCM with overflow checked after dividing by the GCD.
@(export)
lcm :: proc "c" (left, right: u64) -> i64 {
	if left == 0 || right == 0 do return 0
	a, b := left, right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	reduced := left / a
	max_result := u64(9223372036854775807)
	if reduced > max_result / right do return -1
	return i64(reduced * right)
}
