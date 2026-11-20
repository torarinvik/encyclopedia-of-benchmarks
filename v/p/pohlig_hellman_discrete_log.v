module pohlig_hellman_discrete_log

const min_p = i64(3)
const max_p = i64(1009)
const max_factors = 16
const max_parseable_length = 4

struct Factors {
	primes [max_factors]i64
	exponents [max_factors]i64
	count int
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
		if (exponent & 1) != 0 { result = result * factor % modulus }
		factor = factor * factor % modulus
		exponent >>= 1
	}
	return result
}

fn factorize(input_value i64) Factors {
	mut factors := Factors{}
	mut value := input_value
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor != 0 {
			if divisor == 2 { divisor = 3 } else { divisor += 2 }
			continue
		}
		mut exponent := i64(0)
		for value % divisor == 0 {
			value /= divisor
			exponent++
		}
		factors.primes[factors.count] = divisor
		factors.exponents[factors.count] = exponent
		factors.count++
		if divisor == 2 { divisor = 3 } else { divisor += 2 }
	}
	if value > 1 {
		factors.primes[factors.count] = value
		factors.exponents[factors.count] = 1
		factors.count++
	}
	return factors
}

fn prime_order_log(generator i64, target i64, order i64, modulus i64) i64 {
	mut step := i64(1)
	for step * step < order { step++ }
	mut baby := [64]i64{}
	mut value := i64(1)
	for j := 0; j < int(step); j++ {
		baby[j] = value
		value = value * generator % modulus
	}
	giant_factor := pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus)
	mut probe := target
	for i := i64(0); i <= step; i++ {
		for j := 0; j < int(step); j++ {
			if baby[j] == probe {
				candidate := i * step + i64(j)
				if candidate < order { return candidate }
			}
		}
		probe = probe * giant_factor % modulus
	}
	return -1
}

fn inverse_mod(value i64, modulus i64) i64 {
	mut old_r := value
	mut r := modulus
	mut old_s := i64(1)
	mut s := i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_s := old_s - quotient * s
		old_r = r
		r = next_r
		old_s = s
		s = next_s
	}
	if old_r != 1 { return -1 }
	return (old_s % modulus + modulus) % modulus
}

fn pohlig_hellman(p i64, base i64, target i64) i64 {
	if target == 0 { return -2 }
	p_factors := factorize(p - 1)
	mut order := p - 1
	for index := 0; index < p_factors.count; index++ {
		prime := p_factors.primes[index]
		for order % prime == 0 && pow_mod(base, order / prime, p) == 1 { order /= prime }
	}
	if order == 1 { return if target == 1 { i64(0) } else { i64(-2) } }

	order_factors := factorize(order)
	mut solution := i64(0)
	mut combined_modulus := i64(1)
	for index := 0; index < order_factors.count; index++ {
		prime := order_factors.primes[index]
		exponent := order_factors.exponents[index]
		mut component_modulus := i64(1)
		for j := i64(0); j < exponent; j++ { component_modulus *= prime }
		mut partial_log := i64(0)
		mut place := i64(1)
		prime_generator := pow_mod(base, order / prime, p)
		for digit_index := i64(0); digit_index < exponent; digit_index++ {
			current_power := pow_mod(base, partial_log, p)
			inverse_current := pow_mod(current_power, p - 2, p)
			residual := target * inverse_current % p
			digit_target := pow_mod(residual, order / (place * prime), p)
			digit := prime_order_log(prime_generator, digit_target, prime, p)
			if digit < 0 { return -2 }
			partial_log += digit * place
			place *= prime
		}
		if combined_modulus == 1 {
			solution = partial_log
			combined_modulus = component_modulus
		} else {
			inverse := inverse_mod(combined_modulus % component_modulus, component_modulus)
			if inverse < 0 { return -2 }
			difference := (partial_log - solution) % component_modulus
			adjustment := ((difference + component_modulus) % component_modulus) * inverse % component_modulus
			solution += combined_modulus * adjustment
			combined_modulus *= component_modulus
		}
	}
	solution %= order
	if pow_mod(base, solution, p) == target { return solution }
	return -2
}

fn verify(input &i64, length usize) i64 {
	if length != 3 { return -1 }
	p := input[0]
	base := input[1]
	target := input[2]
	if p < min_p || p > max_p || !is_prime(p) || base < 1 || base >= p || target < 0 || target >= p { return -1 }
	return pohlig_hellman(p, base, target)
}

@[export: 'pohlig_hellman_discrete_log']
pub fn pohlig_hellman_discrete_log(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable_length || length != 3 { return -1 }
		return verify(input, length)
	}
}
