package bitwise_addition_recursive

@(export)
bitwise_addition_recursive :: proc "contextless" (first, second: i64) -> i64 {
	if first < 0 || first > 2_147_483_647 || second < 0 || second > 2_147_483_647 do return -1
	return add_recursive(first, second)
}

add_recursive :: proc(first, second: i64) -> i64 {
	bitwise_sum := first ^ second
	carry := first & second
	if carry == 0 do return bitwise_sum
	return add_recursive(bitwise_sum, carry << 1)
}
