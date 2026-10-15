module gcd_recursive_euclidean

// Recursive subtraction-based Euclidean GCD on a bounded positive domain.
fn gcd_recursive_euclidean_step(left u64, right u64) i64 {
	if left == right {
		return i64(left)
	}
	if left > right {
		return gcd_recursive_euclidean_step(left - right, right)
	}
	return gcd_recursive_euclidean_step(left, right - left)
}

@[export: 'gcd_recursive_euclidean']
pub fn gcd_recursive_euclidean(left u64, right u64) i64 {
	if left == 0 || right == 0 || left > 128 || right > 128 {
		return -1
	}
	return gcd_recursive_euclidean_step(left, right)
}
