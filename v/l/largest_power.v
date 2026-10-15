module largest_power

// Legendre's formula for the exponent of prime p in n!.
fn largest_power_is_prime(value u64) bool {
	if value < 2 {
		return false
	}
	mut divisor := u64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 {
			return false
		}
		divisor++
	}
	return true
}

@[export: 'largest_power']
pub fn largest_power(n u64, p u64) i64 {
	if n > 4294967295 || p > 65535 || !largest_power_is_prime(p) {
		return -1
	}
	mut quotient := n
	mut total := i64(0)
	for quotient != 0 {
		quotient /= p
		total += i64(quotient)
	}
	return total
}
