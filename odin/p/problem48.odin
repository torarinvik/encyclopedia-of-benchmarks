package problem48

MODULUS :: i64(10_000_000_000)

@(export)
problem48 :: proc "c" (ignored: i64) -> i64 {
	if ignored != 0 { return -1 }
	total: i64 = 0
	for base: i64 = 1; base <= 1000; base += 1 {
		term: i64 = 1
		for exponent: i64 = 0; exponent < base; exponent += 1 {
			term = (term * base) % MODULUS
		}
		total = (total + term) % MODULUS
	}
	return total
}
