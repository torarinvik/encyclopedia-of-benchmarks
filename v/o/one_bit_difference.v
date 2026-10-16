module one_bit_difference

@[export: 'one_bit_difference']
pub fn one_bit_difference(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	left := input[0]
	right := input[1]
	if left < -2147483648 || left > 2147483647 || right < -2147483648 || right > 2147483647 { return -1 }
	difference := u32(left) ^ u32(right)
	if difference != 0 && (difference & (difference - u32(1))) == 0 { return 1 }
	return 0
}
