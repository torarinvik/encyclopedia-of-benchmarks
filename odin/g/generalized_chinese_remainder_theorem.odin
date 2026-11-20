package generalized_chinese_remainder_theorem

import "core:c"

MAX_PRODUCT :: i64(16_777_216)

modular_inverse :: proc "contextless" (value, modulus: i64) -> i64 {
	old_remainder := value % modulus
	remainder := modulus
	old_coefficient := i64(1)
	coefficient := i64(0)
	for remainder != 0 {
		quotient := old_remainder / remainder
		next_remainder := old_remainder - quotient * remainder
		old_remainder = remainder
		remainder = next_remainder
		next_coefficient := old_coefficient - quotient * coefficient
		old_coefficient = coefficient
		coefficient = next_coefficient
	}
	old_coefficient %= modulus
	if old_coefficient < 0 do old_coefficient += modulus
	return old_coefficient
}

@(export)
generalized_chinese_remainder_theorem :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 10 do return -1
	count := input[0]
	if count < 1 || count > 4 || length != c.size_t(1 + 2 * count) do return -1
	product := i64(1)
	for index := 0; index < int(count); index += 1 {
		residue, modulus := input[1 + 2 * index], input[2 + 2 * index]
        if modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus do return -1
        if product > MAX_PRODUCT / modulus do return -1
		product *= modulus
	}

	powers: [65]i64 = {}
	residues: [65]i64 = {}
	for index := 0; index < int(count); index += 1 {
		residue := input[1 + 2 * index]
		remaining := input[2 + 2 * index]
		for prime := i64(2); prime <= remaining; prime += 1 {
			if remaining % prime != 0 do continue
			prime_power := i64(1)
			for remaining % prime == 0 {
				remaining /= prime
				prime_power *= prime
			}
			if prime_power > powers[int(prime)] {
				powers[int(prime)] = prime_power
				residues[int(prime)] = residue % prime_power
			}
		}
	}
	for index := 0; index < int(count); index += 1 {
		residue := input[1 + 2 * index]
		remaining := input[2 + 2 * index]
		for prime := i64(2); prime <= remaining; prime += 1 {
			if remaining % prime != 0 do continue
			prime_power := i64(1)
			for remaining % prime == 0 {
				remaining /= prime
				prime_power *= prime
			}
			if residues[int(prime)] % prime_power != residue % prime_power do return -2
		}
	}

	solution, combined_modulus := i64(0), i64(1)
	for prime := 2; prime <= 64; prime += 1 {
		modulus := powers[prime]
		if modulus == 0 do continue
		inverse := modular_inverse(combined_modulus % modulus, modulus)
		difference := (residues[prime] - solution % modulus) % modulus
		if difference < 0 do difference += modulus
		multiplier := difference * inverse % modulus
		solution += combined_modulus * multiplier
		combined_modulus *= modulus
		solution %= combined_modulus
	}
	return solution
}
