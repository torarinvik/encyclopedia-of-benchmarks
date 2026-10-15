module bitwise_addition_recursive

fn add_recursive(first i64, second i64) i64 {
	bitwise_sum := first ^ second
	carry := first & second
	if carry == 0 { return bitwise_sum }
	return add_recursive(bitwise_sum, carry << 1)
}

@[export: 'bitwise_addition_recursive']
pub fn bitwise_addition_recursive(first i64, second i64) i64 {
	if first < 0 || first > 2_147_483_647 || second < 0 || second > 2_147_483_647 { return -1 }
	return add_recursive(first, second)
}
