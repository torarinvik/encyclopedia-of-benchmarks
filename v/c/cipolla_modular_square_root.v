module cipolla_modular_square_root

const max_prime = i64(1000003)

struct CipollaPair {
	real i64
	radical i64
}

fn modular_power(base_value i64, exponent_value i64, prime i64) i64 {
	mut result := i64(1)
	mut base := base_value % prime
	mut exponent := exponent_value
	for exponent > 0 {
		if exponent % 2 != 0 { result = (result * base) % prime }
		exponent /= 2
		if exponent > 0 { base = (base * base) % prime }
	}
	return result
}

fn legendre(value i64, prime i64) i64 {
	symbol := modular_power(value % prime, (prime - 1) / 2, prime)
	return if symbol == prime - 1 { -1 } else { symbol }
}

fn multiply(left CipollaPair, right CipollaPair, radicand i64, prime i64) CipollaPair {
	return CipollaPair{
		real: (left.real * right.real + radicand * left.radical * right.radical) % prime,
		radical: (left.real * right.radical + left.radical * right.real) % prime,
	}
}

fn pair_power(base CipollaPair, exponent_value i64, radicand i64, prime i64) CipollaPair {
	mut result := CipollaPair{real: 1, radical: 0}
	mut factor := base
	mut exponent := exponent_value
	for exponent > 0 {
		if exponent % 2 != 0 { result = multiply(result, factor, radicand, prime) }
		exponent /= 2
		if exponent > 0 { factor = multiply(factor, factor, radicand, prime) }
	}
	return result
}

@[export: 'cipolla_modular_square_root']
pub fn cipolla_modular_square_root(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		residue, prime := input[0], input[1]
		if prime < 3 || prime > max_prime || prime % 2 == 0 || residue < 0 || residue >= prime {
			return -1
		}
		if residue == 0 { return 0 }
		if legendre(residue, prime) != 1 { return -1 }

		mut parameter := i64(0)
		mut radicand := i64(0)
		for parameter < prime {
			radicand = (parameter * parameter - residue) % prime
			if radicand < 0 { radicand += prime }
			if legendre(radicand, prime) == -1 { break }
			parameter++
		}
		if parameter == prime { return -1 }

		result := pair_power(CipollaPair{real: parameter, radical: 1},
			(prime + 1) / 2, radicand, prime)
		return if result.real < prime - result.real { result.real } else { prime - result.real }
	}
}
