package exponentiation

@(export, link_name="exponentiation")
exponentiation :: proc "c" (base, exponent: i64) -> i64 {
	if base < 0 || base > 255 || exponent < 0 || exponent > 7 do return -1
	result: i64 = 1
	for i: i64 = 0; i < exponent; i += 1 { result *= base }
	return result
}

main :: proc() {}
