@[export: 'addition_without_arithmetic']
fn addition_without_arithmetic(left_encoded u64, right_encoded u64) i64 {
	if (left_encoded > u64(2147483647) && left_encoded < u64(0xFFFF_FFFF_8000_0000))
		|| (right_encoded > u64(2147483647) && right_encoded < u64(0xFFFF_FFFF_8000_0000)) { return -1 }
	left_value := if left_encoded <= u64(2147483647) { i64(left_encoded) } else { i64(u32(left_encoded)) - 4294967296 }
	right_value := if right_encoded <= u64(2147483647) { i64(right_encoded) } else { i64(u32(right_encoded)) - 4294967296 }
	mut left := u32(left_encoded)
	mut right := u32(right_encoded)
	for right != 0 {
		carry := left & right
		left ^= right
		right = carry << 1
	}
	result := if left <= 2147483647 { i64(left) } else { i64(left) - 4294967296 }
	if (left_value < 0) == (right_value < 0) && (result < 0) != (left_value < 0) { return -1 }
	return result
}
