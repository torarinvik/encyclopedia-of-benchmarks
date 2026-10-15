module powx_n

fn pow_positive(base f64, exponent i64) f64 {
	if exponent == 0 { return 1.0 }
	mut mask := i64(1)
	for mask <= exponent / 2 { mask <<= 1 }
	mut result := base
	mask >>= 1
	for mask != 0 {
		result *= result
		if exponent & mask != 0 { result *= base }
		mask >>= 1
	}
	return result
}

@[export: 'powx_n']
pub fn powx_n(base f64, exponent i32) f64 {
	if exponent == 0 { return 1.0 }
	if exponent == -2147483648 { return 1.0 / (pow_positive(base, 2147483647) * base) }
	if exponent < 0 { return 1.0 / pow_positive(base, -i64(exponent)) }
	return pow_positive(base, i64(exponent))
}
