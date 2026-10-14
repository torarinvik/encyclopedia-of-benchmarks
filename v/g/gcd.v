module gcd

// Portable iterative Euclidean GCD; workload values fit signed 64-bit.
@[export: 'gcd']
pub fn gcd(left u64, right u64) i64 {
	mut dividend := left
	mut divisor := right
	for divisor != 0 {
		remainder := dividend % divisor
		dividend = divisor
		divisor = remainder
	}
	return i64(dividend)
}
