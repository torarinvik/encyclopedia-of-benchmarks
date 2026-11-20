package pohlig_hellman_discrete_log

import "core:c"

MIN_P :: i64(3)
MAX_P :: i64(1009)
MAX_PARSEABLE_LENGTH :: 4

Factorization :: struct {
	primes: [16]i64,
	exponents: [16]i64,
	count: int,
}

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 do return false
		if divisor == 2 do divisor = 3 else divisor += 2
	}
	return true
}

pow_mod :: proc(base_value, exponent_value, modulus: i64) -> i64 {
	result := i64(1)
	factor := base_value % modulus
	exponent := exponent_value
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * factor % modulus
		factor = factor * factor % modulus
		exponent >>= 1
	}
	return result
}

factorize :: proc(input_value: i64) -> Factorization {
	result: Factorization = {}
	value := input_value
	divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor != 0 {
			if divisor == 2 do divisor = 3 else divisor += 2
			continue
		}
		exponent := i64(0)
		for value % divisor == 0 {
			value /= divisor
			exponent += 1
		}
		result.primes[result.count] = divisor
		result.exponents[result.count] = exponent
		result.count += 1
		if divisor == 2 do divisor = 3 else divisor += 2
	}
	if value > 1 {
		result.primes[result.count] = value
		result.exponents[result.count] = 1
		result.count += 1
	}
	return result
}

prime_order_log :: proc(generator, target, order, modulus: i64) -> i64 {
	step := i64(1)
	for step * step < order do step += 1
	 baby: [64]i64
	value := i64(1)
	for j := 0; j < int(step); j += 1 {
		baby[j] = value
		value = value * generator % modulus
	}
	giant_factor := pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus)
	probe := target
	for i := i64(0); i <= step; i += 1 {
		for j := 0; j < int(step); j += 1 {
			if baby[j] == probe {
				candidate := i * step + i64(j)
				if candidate < order do return candidate
			}
		}
		probe = probe * giant_factor % modulus
	}
	return -1
}

inverse_mod :: proc(value, modulus: i64) -> i64 {
	old_r := value
	r := modulus
	old_s := i64(1)
	s := i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_s := old_s - quotient * s
		old_r = r
		r = next_r
		old_s = s
		s = next_s
	}
	if old_r != 1 do return -1
	return (old_s % modulus + modulus) % modulus
}

pohlig_hellman :: proc(p, base, target: i64) -> i64 {
	if target == 0 do return -2
	p_factors := factorize(p - 1)
	order := p - 1
	for i := 0; i < p_factors.count; i += 1 {
		prime := p_factors.primes[i]
		for order % prime == 0 && pow_mod(base, order / prime, p) == 1 do order /= prime
	}
	if order == 1 {
		if target == 1 do return 0
		return -2
	}

	order_factors := factorize(order)
	solution := i64(0)
	combined_modulus := i64(1)
	for i := 0; i < order_factors.count; i += 1 {
		prime := order_factors.primes[i]
		exponent := order_factors.exponents[i]
		component_modulus := i64(1)
		for j := i64(0); j < exponent; j += 1 do component_modulus *= prime
		partial_log := i64(0)
		place := i64(1)
		prime_generator := pow_mod(base, order / prime, p)
		for digit_index := i64(0); digit_index < exponent; digit_index += 1 {
			current_power := pow_mod(base, partial_log, p)
			inverse_current := pow_mod(current_power, p - 2, p)
			residual := target * inverse_current % p
			digit_target := pow_mod(residual, order / (place * prime), p)
			digit := prime_order_log(prime_generator, digit_target, prime, p)
			if digit < 0 do return -2
			partial_log += digit * place
			place *= prime
		}
		if combined_modulus == 1 {
			solution = partial_log
			combined_modulus = component_modulus
		} else {
			inverse := inverse_mod(combined_modulus % component_modulus, component_modulus)
			if inverse < 0 do return -2
			difference := (partial_log - solution) % component_modulus
			adjustment := ((difference + component_modulus) % component_modulus) * inverse % component_modulus
			solution += combined_modulus * adjustment
			combined_modulus *= component_modulus
		}
	}
	solution %= order
	if pow_mod(base, solution, p) == target do return solution
	return -2
}

verify :: proc(input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	p := input[0]
	base := input[1]
	target := input[2]
	if p < MIN_P || p > MAX_P || !is_prime(p) || base < 1 || base >= p || target < 0 || target >= p do return -1
	return pohlig_hellman(p, base, target)
}

@(export)
pohlig_hellman_discrete_log :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) || length != 3 do return -1
	return verify(input, length)
}
