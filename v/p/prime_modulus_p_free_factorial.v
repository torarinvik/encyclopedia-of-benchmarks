module prime_modulus_p_free_factorial

const max_prime = i64(1009)

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

@[export: 'prime_modulus_p_free_factorial']
pub fn prime_modulus_p_free_factorial(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		n := input[0]
		prime := input[1]
		if n < 0 || prime < 2 || prime > max_prime || !is_prime(prime) { return -1 }

		mut factorial := [1009]i64{}
		factorial[0] = 1
		for value in 1 .. int(prime) {
			factorial[value] = factorial[value - 1] * i64(value) % prime
		}

		mut result := i64(1)
		mut remaining := n
		for remaining > 0 {
			quotient := remaining / prime
			residue := int(remaining % prime)
			mut block := factorial[residue]
			if quotient % 2 != 0 { block = prime - block }
			result = result * block % prime
			remaining = quotient
		}
		return result
	}
}
