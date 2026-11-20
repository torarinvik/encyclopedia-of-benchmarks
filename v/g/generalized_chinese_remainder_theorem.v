module generalized_chinese_remainder_theorem

const max_product = i64(16_777_216)

fn modular_inverse(value i64, modulus i64) i64 {
	mut old_remainder := value % modulus
	mut remainder := modulus
	mut old_coefficient := i64(1)
	mut coefficient := i64(0)
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
	if old_coefficient < 0 { old_coefficient += modulus }
	return old_coefficient
}

@[export: 'generalized_chinese_remainder_theorem']
pub fn generalized_chinese_remainder_theorem(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 10 { return -1 }
	unsafe {
		count := input[0]
		if count < 1 || count > 4 || length != usize(1 + 2 * count) { return -1 }
		mut product := i64(1)
		for index := 0; index < int(count); index++ {
			residue, modulus := input[1 + 2 * index], input[2 + 2 * index]
            if modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus { return -1 }
            if product > max_product / modulus { return -1 }
			product *= modulus
		}
		mut powers := [65]i64{}
		mut residues := [65]i64{}
		for index := 0; index < int(count); index++ {
			residue := input[1 + 2 * index]
			mut remaining := input[2 + 2 * index]
			mut prime := i64(2)
			for prime <= remaining {
				if remaining % prime == 0 {
					mut prime_power := i64(1)
					for remaining % prime == 0 {
						remaining /= prime
						prime_power *= prime
					}
					if prime_power > powers[int(prime)] {
						powers[int(prime)] = prime_power
						residues[int(prime)] = residue % prime_power
					}
				}
				prime++
			}
		}
		for index := 0; index < int(count); index++ {
			residue := input[1 + 2 * index]
			mut remaining := input[2 + 2 * index]
			mut prime := i64(2)
			for prime <= remaining {
				if remaining % prime == 0 {
					mut prime_power := i64(1)
					for remaining % prime == 0 {
						remaining /= prime
						prime_power *= prime
					}
					if residues[int(prime)] % prime_power != residue % prime_power { return -2 }
				}
				prime++
			}
		}
		mut solution := i64(0)
		mut combined_modulus := i64(1)
		for prime := 2; prime <= 64; prime++ {
			modulus := powers[prime]
			if modulus == 0 { continue }
			inverse := modular_inverse(combined_modulus % modulus, modulus)
			mut difference := (residues[prime] - solution % modulus) % modulus
			if difference < 0 { difference += modulus }
			multiplier := difference * inverse % modulus
			solution += combined_modulus * multiplier
			combined_modulus *= modulus
			solution %= combined_modulus
		}
		return solution
	}
}
