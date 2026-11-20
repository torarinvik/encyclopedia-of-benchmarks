module multiplicative_order

fn gcd_i64(a_input i64, b_input i64) i64 {
	mut a := a_input
	mut b := b_input
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn pow_mod_i64(base_input i64, exponent_input i64, modulus i64) i64 {
	mut base := base_input % modulus
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

fn totient_i64(value i64) i64 {
	mut remaining := value
	mut result := value
	mut prime := i64(2)
	for prime * prime <= remaining {
		if remaining % prime == 0 {
			result = result / prime * (prime - 1)
			for remaining % prime == 0 { remaining /= prime }
		}
		prime++
	}
	if remaining > 1 { result = result / remaining * (remaining - 1) }
	return result
}

fn reduce_order(base i64, modulus i64, initial_order i64) i64 {
	mut remaining := initial_order
	mut order := initial_order
	mut prime := i64(2)
	for prime * prime <= remaining {
		if remaining % prime == 0 {
			for remaining % prime == 0 { remaining /= prime }
			for order % prime == 0 && pow_mod_i64(base, order / prime, modulus) == 1 { order /= prime }
		}
		prime++
	}
	if remaining > 1 {
		for order % remaining == 0 && pow_mod_i64(base, order / remaining, modulus) == 1 { order /= remaining }
	}
	return order
}

@[export: 'multiplicative_order']
pub fn multiplicative_order(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		base, modulus := input[0], input[1]
		if modulus < 2 || modulus > 1000 || base < 0 || base >= modulus { return -1 }
		if gcd_i64(base, modulus) != 1 { return 0 }
		return reduce_order(base, modulus, totient_i64(modulus))
	}
}
