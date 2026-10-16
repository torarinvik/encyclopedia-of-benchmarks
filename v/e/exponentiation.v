module exponentiation

@[export: 'exponentiation']
pub fn exponentiation(base i64, exponent i64) i64 {
	if base < 0 || base > 255 || exponent < 0 || exponent > 7 { return -1 }
	mut result := i64(1)
	for _ in 0 .. int(exponent) { result *= base }
	return result
}
