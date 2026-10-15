package gcd_recursive_euclidean

// Recursive subtraction-based Euclidean GCD on a bounded positive domain.
gcd_recursive_euclidean_step :: proc "contextless" (left, right: u64) -> i64 {
	if left == right do return i64(left)
	if left > right do return gcd_recursive_euclidean_step(left - right, right)
	return gcd_recursive_euclidean_step(left, right - left)
}

@(export)
gcd_recursive_euclidean :: proc "c" (left, right: u64) -> i64 {
	if left == 0 || right == 0 || left > 128 || right > 128 do return -1
	return gcd_recursive_euclidean_step(left, right)
}
