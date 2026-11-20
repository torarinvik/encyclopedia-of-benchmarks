module pocklington_primality_certificate

const max_n = i64(65535)
const max_factors = i64(6)
const max_exponent = i64(16)
const max_length = 22

fn gcd_i64(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		if divisor == 2 { divisor = 3 } else { divisor += 2 }
	}
	return true
}

fn pow_mod(base_value i64, exponent_value i64, modulus i64) i64 {
	mut result := i64(1)
	mut factor := base_value % modulus
	mut exponent := exponent_value
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * factor) % modulus }
		factor = (factor * factor) % modulus
		exponent >>= 1
	}
	return result
}

fn verify_certificate(values &i64, length usize) i64 {
	if length < 2 || length > max_length { return -1 }
	n := values[0]
	count := values[1]
	if n < 3 || n > max_n || count < 1 || count > max_factors { return -1 }
	if length != usize(3 + 3 * count) { return -1 }

	mut factored_part := i64(1)
	mut previous_prime := i64(1)
	for index := 0; index < int(count); index++ {
		offset := 2 + 3 * index
		prime := values[offset]
		exponent := values[offset + 1]
		witness := values[offset + 2]
		if prime <= previous_prime || prime < 2 || exponent < 1 || exponent > max_exponent || witness < 1 || witness >= n || !is_prime(prime) { return -1 }
		previous_prime = prime
		for power_index := i64(0); power_index < exponent; power_index++ {
			if factored_part > (n - 1) / prime { return -1 }
			factored_part *= prime
		}
	}
	cofactor := values[2 + 3 * int(count)]
	if cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1 { return -1 }
	if factored_part * factored_part <= n { return 0 }

	for index := 0; index < int(count); index++ {
		offset := 2 + 3 * index
		prime := values[offset]
		witness := values[offset + 2]
		if pow_mod(witness, n - 1, n) != 1 { return 0 }
		reduced := pow_mod(witness, (n - 1) / prime, n)
		difference := (reduced + n - 1) % n
		if gcd_i64(difference, n) != 1 { return 0 }
	}
	return 1
}

@[export: 'pocklington_primality_certificate']
pub fn pocklington_primality_certificate(input &i64, length usize) i64 {
	unsafe {
		if input == nil { return -1 }
		return verify_certificate(input, length)
	}
}
