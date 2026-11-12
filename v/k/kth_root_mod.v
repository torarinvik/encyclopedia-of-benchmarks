module kth_root_mod

const max_t = 8
const max_k = i64(1_000_000_000)
const max_p = i64(1_000)

fn modular_power(base_input i64, exponent_input i64, modulus i64) i64 {
	mut base := base_input % modulus
	mut exponent := exponent_input
	mut result := i64(1) % modulus
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn factor_distinct(value_input i64) ([16]i64, int) {
	mut value := value_input
	mut factors := [16]i64{}
	mut count := 0
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 {
			factors[count] = divisor
			count++
			for value % divisor == 0 { value /= divisor }
		}
		divisor++
	}
	if value > 1 { factors[count] = value; count++ }
	return factors, count
}

fn primitive_root(prime i64) i64 {
	if prime == 2 { return 1 }
	order := prime - 1
	factors, count := factor_distinct(order)
	for candidate := i64(2); candidate < prime; candidate++ {
		mut index := 0
		for index < count && modular_power(candidate, order / factors[index], prime) != 1 { index++ }
		if index == count { return candidate }
	}
	return -1
}

fn gcd_i64(a_input i64, b_input i64) i64 {
	mut a := a_input
	mut b := b_input
	for b != 0 { remainder := a % b; a = b; b = remainder }
	return a
}

fn modular_inverse(value i64, modulus i64) i64 {
	mut old_t := i64(0)
	mut new_t := i64(1)
	mut old_r := modulus
	mut new_r := value % modulus
	for new_r != 0 {
		quotient := old_r / new_r
		next_t := old_t - quotient * new_t
		next_r := old_r - quotient * new_r
		old_t = new_t; new_t = next_t; old_r = new_r; new_r = next_r
	}
	if old_t < 0 { old_t += modulus }
	return old_t
}

fn kth_root(exponent i64, residue i64, prime i64) i64 {
	if exponent == 0 { return if residue == 1 { 0 } else { -1 } }
	if residue == 0 { return 0 }
	order := prime - 1
	generator := primitive_root(prime)
	mut power := i64(1)
	mut discrete_log := i64(-1)
	for candidate := i64(0); candidate < order; candidate++ {
		if power == residue { discrete_log = candidate; break }
		power = power * generator % prime
	}
	if discrete_log < 0 { return -1 }
	common := gcd_i64(exponent, order)
	if discrete_log % common != 0 { return -1 }
	reduced_order := order / common
	mut root_exponent := i64(0)
	if reduced_order > 1 {
		inverse := modular_inverse((exponent / common) % reduced_order, reduced_order)
		root_exponent = (discrete_log / common) * inverse % reduced_order
	}
	root := modular_power(generator, root_exponent, prime)
	return if modular_power(root, exponent, prime) == residue { root } else { -1 }
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'kth_root_mod']
pub fn kth_root_mod(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(1 + 3 * max_t) { return -1 }
		t_value := input[0]
		if t_value < 1 || t_value > max_t { return -1 }
		t := int(t_value)
		if length != usize(1 + 3 * t) { return -1 }
		mut triples := [3 * max_t]i64{}
		for i := 0; i < 3 * t; i += 3 {
			exponent, residue, prime := input[i + 1], input[i + 2], input[i + 3]
			if exponent < 0 || exponent > max_k || prime < 2 || prime > max_p || residue < 0 || residue >= prime || !is_prime(prime) { return -1 }
			triples[i] = exponent; triples[i + 1] = residue; triples[i + 2] = prime
		}
		required := 8 * t
		if output == nil || capacity < usize(required) { return -2 }
		for test in 0 .. t {
			put_i64_le(mut output, 8 * test, kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]))
		}
		return i64(required)
	}
}
