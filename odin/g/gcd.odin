package gcd

// Portable iterative Euclidean GCD; workload values fit signed 64-bit.
@(export)
gcd :: proc "c" (left, right: u64) -> i64 {
	dividend := left
	divisor := right
	for divisor != 0 {
		remainder := dividend % divisor
		dividend = divisor
		divisor = remainder
	}
	return i64(dividend)
}
