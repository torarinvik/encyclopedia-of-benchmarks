package powx_n

pow_positive :: proc "contextless" (base: f64, exponent: i64) -> f64 {
	if exponent == 0 do return 1.0
	mask := i64(1)
	for mask <= exponent / 2 { mask <<= 1 }
	result := base
	mask >>= 1
	for mask != 0 {
		result *= result
		if (exponent & mask) != 0 do result *= base
		mask >>= 1
	}
	return result
}

@(export)
powx_n :: proc "c" (base: f64, exponent: i32) -> f64 {
	if exponent == 0 do return 1.0
	if exponent == -2147483648 do return 1.0 / (pow_positive(base, 2147483647) * base)
	if exponent < 0 do return 1.0 / pow_positive(base, -i64(exponent))
	return pow_positive(base, i64(exponent))
}
