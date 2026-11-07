module first_different_bit

// Return the trailing-zero count of the signed 32-bit XOR.
@[export: 'first_different_bit']
pub fn first_different_bit(x i64, y i64) i64 {
	if x < i64(-2147483647) - 1 || x > i64(2147483647) || y < i64(-2147483647) - 1 || y > i64(2147483647) {
		return -1
	}
	mut difference := u32(i32(x)) ^ u32(i32(y))
	mut index := i64(0)
	for index < 32 && (difference & u32(1)) == 0 {
		index++
		difference >>= 1
	}
	return index
}
