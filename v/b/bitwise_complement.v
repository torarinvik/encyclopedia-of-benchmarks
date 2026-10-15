module bitwise_complement

// Complement only the significant binary digits of a nonnegative integer.
@[export: 'bitwise_complement']
pub fn bitwise_complement(n i64) i64 {
	if n < 0 || n > 2147483647 { return -1 }
	if n == 0 { return 1 }
	mut value := u64(n)
	mut mask := u64(0)
	for value != 0 {
		mask = (mask << 1) | 1
		value >>= 1
	}
	return n ^ i64(mask)
}
