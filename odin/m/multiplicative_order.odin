package multiplicative_order

import "core:c"

gcd_i64 :: proc "contextless" (a_input, b_input: i64) -> i64 {
	a, b := a_input, b_input
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

pow_mod_i64 :: proc "contextless" (base_input, exponent_input, modulus: i64) -> i64 {
	base, exponent := base_input % modulus, exponent_input
	result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

totient_i64 :: proc "contextless" (value: i64) -> i64 {
	remaining, result := value, value
	for prime := i64(2); prime*prime <= remaining; prime += 1 {
		if remaining % prime == 0 {
			result = result / prime * (prime - 1)
			for remaining % prime == 0 { remaining /= prime }
		}
	}
	if remaining > 1 { result = result / remaining * (remaining - 1) }
	return result
}

reduce_order :: proc "contextless" (base, modulus, initial_order: i64) -> i64 {
	remaining, order := initial_order, initial_order
	for prime := i64(2); prime*prime <= remaining; prime += 1 {
		if remaining % prime == 0 {
			for remaining % prime == 0 { remaining /= prime }
			for order % prime == 0 && pow_mod_i64(base, order/prime, modulus) == 1 { order /= prime }
		}
	}
	if remaining > 1 {
		for order % remaining == 0 && pow_mod_i64(base, order/remaining, modulus) == 1 { order /= remaining }
	}
	return order
}

@(export)
multiplicative_order :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	base, modulus := input[0], input[1]
	if modulus < 2 || modulus > 1000 || base < 0 || base >= modulus do return -1
	if gcd_i64(base, modulus) != 1 do return 0
	return reduce_order(base, modulus, totient_i64(modulus))
}
