package first_different_bit

INT32_MIN_VALUE :: i64(-2_147_483_648)
INT32_MAX_VALUE :: i64(2_147_483_647)

// Return the trailing-zero count of the signed 32-bit XOR.
@(export)
first_different_bit :: proc "c" (x, y: i64) -> i64 {
	if x < INT32_MIN_VALUE || x > INT32_MAX_VALUE || y < INT32_MIN_VALUE || y > INT32_MAX_VALUE do return -1
	difference := u32(i32(x)) ~ u32(i32(y))
	index := i64(0)
	for index < 32 && (difference & 1) == 0 {
		index += 1
		difference = difference >> 1
	}
	return index
}
