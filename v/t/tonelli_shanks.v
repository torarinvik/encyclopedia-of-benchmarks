module tonelli_shanks

fn mod_pow(base_value i64, exponent_value i64, modulus i64) i64 {
	mut base := base_value % modulus
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn legendre_symbol(residue i64, prime i64) i64 {
	symbol := mod_pow(residue % prime, (prime - 1) / 2, prime)
	if symbol == prime - 1 { return -1 }
	return symbol
}

@[export: 'tonelli_shanks']
pub fn tonelli_shanks(packed &i64, length usize) i64 {
	if length != 2 { return -1 }
	mut residue := unsafe { packed[0] }
	prime := unsafe { packed[1] }
	if prime <= 2 || prime & 1 == 0 || prime > 1000003 || residue < 0 || residue >= prime { return -1 }
	if residue == 0 { return 0 }
	if legendre_symbol(residue, prime) != 1 { return -1 }
	if prime % 4 == 3 {
		root := mod_pow(residue, (prime + 1) / 4, prime)
		if root < prime - root { return root }
		return prime - root
	}
	mut q := prime - 1
	mut s := i64(0)
	for q & 1 == 0 { q /= 2; s++ }
	mut non_residue := i64(2)
	for legendre_symbol(non_residue, prime) != -1 { non_residue++ }
	mut c := mod_pow(non_residue, q, prime)
	mut r := mod_pow(residue, (q + 1) / 2, prime)
	mut t := mod_pow(residue, q, prime)
	mut remaining_s := s
	for t != 1 {
		mut test_power := t
		mut least_i := i64(0)
		mut candidate_i := i64(1)
		for candidate_i < remaining_s {
			test_power = mod_pow(test_power, 2, prime)
			if test_power == 1 { least_i = candidate_i; break }
			candidate_i++
		}
		if least_i == 0 { return -1 }
		b := mod_pow(c, i64(1) << (remaining_s - least_i - 1), prime)
		r = (r * b) % prime
		c = (b * b) % prime
		t = (t * c) % prime
		remaining_s = least_i
	}
	if r < prime - r { return r }
	return prime - r
}
