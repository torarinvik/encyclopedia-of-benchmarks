fn bitwise_add(a i64, b i64) i64 {
	mut left := u64(a)
	mut right := u64(b)
	for right != 0 {
		partial := left ^ right
		right = (left & right) << 1
		left = partial
	}
	if left <= 0x7fffffffffffffff { return i64(left) }
	return -1 - i64(~left)
}

@[export: 'sum_of_two_integers']
pub fn sum_of_two_integers(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != 2 { return -1 }
	if unsafe { values[0] < -2147483648 || values[0] > 2147483647 || values[1] < -2147483648 || values[1] > 2147483647 } { return -1 }
	return bitwise_add(unsafe { values[0] }, unsafe { values[1] })
}
