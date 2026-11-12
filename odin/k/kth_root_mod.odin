package kth_root_mod

import "core:c"

max_t :: 8
max_k :: i64(1_000_000_000)
max_p :: i64(1_000)

modular_power :: proc(base_input, exponent_input, modulus: i64) -> i64 {
	base := base_input % modulus
	exponent := exponent_input
	result := i64(1) % modulus
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

is_prime :: proc(value: i64) -> bool {
	if value < 2 { return false }
	for divisor := i64(2); divisor * divisor <= value; divisor += 1 {
		if value % divisor == 0 { return false }
	}
	return true
}

factor_distinct :: proc(value_input: i64, factors: ^[16]i64) -> int {
	value := value_input
	count := 0
	for divisor := i64(2); divisor * divisor <= value; divisor += 1 {
		if value % divisor == 0 {
			factors[count] = divisor
			count += 1
			for value % divisor == 0 { value /= divisor }
		}
	}
	if value > 1 { factors[count] = value; count += 1 }
	return count
}

primitive_root :: proc(prime: i64) -> i64 {
	if prime == 2 { return 1 }
	order := prime - 1
	factors: [16]i64
	count := factor_distinct(order, &factors)
	for candidate := i64(2); candidate < prime; candidate += 1 {
		index := 0
		for index < count && modular_power(candidate, order / factors[index], prime) != 1 { index += 1 }
		if index == count { return candidate }
	}
	return -1
}

gcd_i64 :: proc(a_input, b_input: i64) -> i64 {
	a, b := a_input, b_input
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

modular_inverse :: proc(value, modulus: i64) -> i64 {
	old_t, new_t := i64(0), i64(1)
	old_r, new_r := modulus, value % modulus
	for new_r != 0 {
		quotient := old_r / new_r
		next_t, next_r := old_t - quotient * new_t, old_r - quotient * new_r
		old_t, new_t, old_r, new_r = new_t, next_t, new_r, next_r
	}
	if old_t < 0 { old_t += modulus }
	return old_t
}

kth_root :: proc(exponent, residue, prime: i64) -> i64 {
	if exponent == 0 { if residue == 1 { return 0 }; return -1 }
	if residue == 0 { return 0 }
	order := prime - 1
	generator := primitive_root(prime)
	power, discrete_log := i64(1), i64(-1)
	for candidate := i64(0); candidate < order; candidate += 1 {
		if power == residue { discrete_log = candidate; break }
		power = power * generator % prime
	}
	if discrete_log < 0 { return -1 }
	common := gcd_i64(exponent, order)
	if discrete_log % common != 0 { return -1 }
	reduced_order := order / common
	root_exponent := i64(0)
	if reduced_order > 1 {
		inverse := modular_inverse((exponent / common) % reduced_order, reduced_order)
		root_exponent = (discrete_log / common) * inverse % reduced_order
	}
	root := modular_power(generator, root_exponent, prime)
	if modular_power(root, exponent, prime) == residue { return root }
	return -1
}

put_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
kth_root_mod :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 1 + 3 * max_t { return -1 }
	t_value := input[0]
	if t_value < 1 || t_value > max_t { return -1 }
	t := int(t_value)
	if int(length) != 1 + 3 * t { return -1 }
	triples: [3 * max_t]i64
	for i := 0; i < 3 * t; i += 3 {
		exponent, residue, prime := input[i + 1], input[i + 2], input[i + 3]
		if exponent < 0 || exponent > max_k || prime < 2 || prime > max_p || residue < 0 || residue >= prime || !is_prime(prime) { return -1 }
		triples[i], triples[i + 1], triples[i + 2] = exponent, residue, prime
	}
	required := 8 * t
	if output == nil || capacity < c.size_t(required) { return -2 }
	for test := 0; test < t; test += 1 {
		put_i64_le(output, 8 * test, kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]))
	}
	return i64(required)
}
