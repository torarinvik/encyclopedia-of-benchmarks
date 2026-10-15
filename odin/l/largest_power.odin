package largest_power

// Legendre's formula for the exponent of prime p in n!.
largest_power_is_prime :: proc(value: u64) -> bool {
	if value < 2 {
		return false
	}
	for divisor: u64 = 2; divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 {
			return false
		}
	}
	return true
}

@(export)
largest_power :: proc "c" (n, p: u64) -> i64 {
	if n > 4294967295 || p > 65535 || !largest_power_is_prime(p) {
		return -1
	}
	quotient := n
	total: i64 = 0
	for quotient != 0 {
		quotient /= p
		total += i64(quotient)
	}
	return total
}
