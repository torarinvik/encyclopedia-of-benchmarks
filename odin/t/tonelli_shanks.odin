package tonelli_shanks

import "core:c"

mod_pow :: proc(base_value, exponent_value, modulus: i64) -> i64 {
	base := base_value % modulus
	exponent := exponent_value
	result: i64 = 1
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % modulus
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

legendre_symbol :: proc(residue, prime: i64) -> i64 {
	symbol := mod_pow(residue % prime, (prime - 1) / 2, prime)
	if symbol == prime - 1 do return -1
	return symbol
}

@(export)
tonelli_shanks :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length != 2 do return -1
	residue := packed[0]
	prime := packed[1]
	if prime <= 2 || (prime & 1) == 0 || prime > 1000003 || residue < 0 || residue >= prime do return -1
	if residue == 0 do return 0
	if legendre_symbol(residue, prime) != 1 do return -1
	if prime % 4 == 3 {
		root := mod_pow(residue, (prime + 1) / 4, prime)
		if root < prime - root do return root
		return prime - root
	}
	q := prime - 1
	s: i64 = 0
	for (q & 1) == 0 { q /= 2; s += 1 }
	non_residue: i64 = 2
	for legendre_symbol(non_residue, prime) != -1 { non_residue += 1 }
	c := mod_pow(non_residue, q, prime)
	r := mod_pow(residue, (q + 1) / 2, prime)
	t := mod_pow(residue, q, prime)
	remaining_s := s
	for t != 1 {
		test_power := t
		least_i: i64 = 0
		for candidate_i: i64 = 1; candidate_i < remaining_s; candidate_i += 1 {
			test_power = mod_pow(test_power, 2, prime)
			if test_power == 1 { least_i = candidate_i; break }
		}
		if least_i == 0 do return -1
		b := mod_pow(c, i64(1) << (remaining_s - least_i - 1), prime)
		r = (r * b) % prime
		c = (b * b) % prime
		t = (t * c) % prime
		remaining_s = least_i
	}
	if r < prime - r do return r
	return prime - r
}
