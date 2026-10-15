package bitwise_gcd

trailing_zeros :: proc(value: u64) -> int {
	count := 0
	current := value
	for (current & 1) == 0 {
		current >>= 1
		count += 1
	}
	return count
}

@(export)
bitwise_gcd :: proc "c" (left, right: u64) -> i64 {
	if left == 0 do return i64(right)
	if right == 0 do return i64(left)

	common_twos := trailing_zeros(left | right)
	a := left >> trailing_zeros(left)
	b := right
	for b != 0 {
		b >>= trailing_zeros(b)
		if a > b {
			a, b = b, a
		}
		b -= a
	}
	return i64(a << common_twos)
}
