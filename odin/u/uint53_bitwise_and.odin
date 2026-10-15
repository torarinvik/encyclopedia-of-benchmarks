package main

@(export, link_name="uint53_bitwise_and")
uint53_bitwise_and :: proc(n, m: i64) -> i64 {
	if n < 0 || m < 0 || n > 9007199254740991 || m > 9007199254740991 do return -1
	left := n
	right := m
	result: i64 = 0
	bit: i64 = 1
	for left != 0 && right != 0 {
		left_bit := left % 2
		right_bit := right % 2
		result += left_bit * right_bit * bit
		left = (left - left_bit) / 2
		right = (right - right_bit) / 2
		bit *= 2
	}
	return result
}

main :: proc() {}
