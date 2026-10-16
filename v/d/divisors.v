module divisors

// Encode the source divisor list in a lossless positive signed-i64 bit mask.
@[export: 'divisors']
pub fn divisors(values &i64, length usize) i64 {
	if length != 1 || unsafe { values == nil } { return -1 }
	n := unsafe { values[0] }
	if n < 1 || n > 62 { return -1 }
	mut mask := u64(0)
	for divisor := i64(1); divisor <= n; divisor++ {
		if n % divisor == 0 { mask |= u64(1) << u32(divisor) }
	}
	return i64(mask)
}
