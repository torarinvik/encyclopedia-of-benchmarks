package cipolla_modular_square_root

import "core:c"

normalize :: proc(value, prime: i64) -> i64 {
	remainder := value % prime
	if remainder < 0 do remainder += prime
	return remainder
}

modular_power :: proc(base_value, exponent_value, prime: i64) -> i64 {
	base := normalize(base_value, prime)
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % prime
		exponent >>= 1
		if exponent > 0 do base = (base * base) % prime
	}
	return result
}

legendre_symbol :: proc(value, prime: i64) -> i64 {
	symbol := modular_power(value, (prime - 1) / 2, prime)
	if symbol == prime - 1 do return -1
	return symbol
}

pair_real :: proc(a, b, c_value, e, radicand, prime: i64) -> i64 {
	return (a * c_value + radicand * b * e) % prime
}

pair_imaginary :: proc(a, b, c_value, e, prime: i64) -> i64 {
	return (a * e + b * c_value) % prime
}

@(export)
cipolla_modular_square_root :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length != c.size_t(2) do return -1
	residue := packed[0]
	prime := packed[1]
	if prime < 3 || prime > 1000003 || (prime & 1) == 0 || residue < 0 || residue >= prime do return -1
	if residue == 0 do return 0
	if legendre_symbol(residue, prime) != 1 do return -1

	parameter := i64(0)
	radical := i64(0)
	found := false
	for parameter < prime {
		radical = normalize(parameter * parameter - residue, prime)
		if legendre_symbol(radical, prime) == -1 { found = true; break }
		parameter += 1
	}
	if !found do return -1

	result_real := i64(1)
	result_imaginary := i64(0)
	base_real := parameter
	base_imaginary := i64(1)
	exponent := (prime + 1) / 2
	for exponent > 0 {
		if (exponent & 1) != 0 {
			next_real := pair_real(result_real, result_imaginary, base_real, base_imaginary, radical, prime)
			next_imaginary := pair_imaginary(result_real, result_imaginary, base_real, base_imaginary, prime)
			result_real = next_real
			result_imaginary = next_imaginary
		}
		exponent >>= 1
		if exponent > 0 {
			next_base_real := pair_real(base_real, base_imaginary, base_real, base_imaginary, radical, prime)
			next_base_imaginary := pair_imaginary(base_real, base_imaginary, base_real, base_imaginary, prime)
			base_real = next_base_real
			base_imaginary = next_base_imaginary
		}
	}
	if result_imaginary != 0 do return -1
	if result_real < prime - result_real do return result_real
	return prime - result_real
}
