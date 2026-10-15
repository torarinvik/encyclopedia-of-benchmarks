package sum_of_two_integers

import "core:c"

bitwise_add :: proc "contextless" (a, b: i64) -> i64 {
	left, right := u64(a), u64(b)
	for right != 0 {
		partial := left ^ right
		right = (left & right) << 1
		left = partial
	}
	if left <= 0x7fffffffffffffff do return i64(left)
	return -1 - i64(~left)
}

@(export)
sum_of_two_integers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	if values[0] < -2147483648 || values[0] > 2147483647 || values[1] < -2147483648 || values[1] > 2147483647 do return -1
	return bitwise_add(values[0], values[1])
}
