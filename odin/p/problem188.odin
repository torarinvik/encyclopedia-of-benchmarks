package problem188

modexpt :: proc(base, exponent, modulus: i64) -> i64 {
	if exponent == 1 do return base
	if exponent % 2 == 0 {
		half := modexpt(base, exponent / 2, modulus) % modulus
		return (half * half) % modulus
	}
	return (base * modexpt(base, exponent - 1, modulus)) % modulus
}

@(export)
problem188 :: proc "c" (base, height, digits: i64) -> i64 {
	if base < 1 || base > 1_000_000_000 || base % 10 == 0 || height < 1 || height > 10_000 || digits < 1 || digits > 8 do return -1
	modulus := i64(1)
	for index := i64(0); index < digits; index += 1 { modulus *= 10 }
	result := base
	for level := i64(1); level < height; level += 1 { result = modexpt(base, result, modulus) }
	return result
}
