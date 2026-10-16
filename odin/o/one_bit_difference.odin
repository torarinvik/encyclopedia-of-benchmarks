package one_bit_difference

@(export)
one_bit_difference :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	left := input[0]
	right := input[1]
	if left < -2147483648 || left > 2147483647 || right < -2147483648 || right > 2147483647 do return -1
	difference := u32(left) ^ u32(right)
	if difference != 0 && (difference & (difference - 1)) == 0 do return 1
	return 0
}
