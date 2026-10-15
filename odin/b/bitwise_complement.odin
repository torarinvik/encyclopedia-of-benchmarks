package bitwise_complement

// Complement only the significant binary digits of a nonnegative integer.
@(export)
bitwise_complement :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > 2_147_483_647 do return -1
	if n == 0 do return 1
	value := u64(n)
	mask: u64 = 0
	for value != 0 {
		mask = (mask << 1) | 1
		value >>= 1
	}
	return n ~ i64(mask)
}
