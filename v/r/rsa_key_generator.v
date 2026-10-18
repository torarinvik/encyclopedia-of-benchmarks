module rsa_key_generator

const invalid_result = i64(-1)
const min_key_size = i64(2)
const max_key_size = i64(20)
const max_draws = i64(1024)
const max_packed_length = 1027
const fnv_offset_basis = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)
const low63_mask = u64(0x7fffffffffffffff)

fn rsa_key_generator_draw(values &i64, length usize, mut cursor usize, low i64, high i64) ?i64 {
	if cursor >= length { return none }
	value := unsafe { values[cursor] }
	cursor++
	if value < low || value >= high { return none }
	return value
}

fn gcd_i64(a_input i64, b_input i64) i64 {
	mut a := a_input
	mut b := b_input
	for b != 0 { remainder := a % b; a = b; b = remainder }
	if a < 0 { return -a }
	return a
}

fn power_mod_i64(base i64, exponent_input i64, modulus i64) i64 {
	mut exponent := exponent_input
	mut result := i64(1)
	mut power := base % modulus
	for exponent > 0 {
		if exponent & 1 != 0 { result = (result * power) % modulus }
		power = (power * power) % modulus
		exponent /= 2
	}
	return result
}

fn rsa_key_generator_rabin_miller(num i64, values &i64, length usize, mut cursor usize) ?bool {
	mut s := num - 1
	mut t := i64(0)
	for s % 2 == 0 { s /= 2; t++ }
	for _ in 0 .. 5 {
		base := rsa_key_generator_draw(values, length, mut cursor, 2, num - 1) or { return none }
	mut value := power_mod_i64(base, s, num)
		if value != 1 {
			mut i := i64(0)
			for value != num - 1 {
				if i == t - 1 { return false }
				i++
				value = (value * value) % num
			}
		}
	}
	return true
}

fn rsa_key_generator_is_prime_low_num(num i64, values &i64, length usize, mut cursor usize) ?bool {
	if num < 2 { return false }
	if num <= 997 {
		mut divisor := i64(2)
		for divisor * divisor <= num {
			if num % divisor == 0 { return false }
			divisor++
		}
		return true
	}
	mut divisor := i64(2)
	for divisor <= 997 {
		if num % divisor == 0 { return false }
		divisor++
	}
	return rsa_key_generator_rabin_miller(num, values, length, mut cursor)
}

fn rsa_key_generator_generate_large_prime(key_size i64, values &i64, length usize, mut cursor usize) ?i64 {
	low := i64(1) << (key_size - 1)
	high := i64(1) << key_size
	for {
		candidate := rsa_key_generator_draw(values, length, mut cursor, low, high) or { return none }
		is_prime := rsa_key_generator_is_prime_low_num(candidate, values, length, mut cursor) or { return none }
		if is_prime { return candidate }
	}
	return none
}

fn find_mod_inverse(a i64, modulus i64) i64 {
	if gcd_i64(a, modulus) != 1 { return invalid_result }
	mut u1 := i64(1)
	mut u2 := i64(0)
	mut u3 := a
	mut v1 := i64(0)
	mut v2 := i64(1)
	mut v3 := modulus
	for v3 != 0 {
		quotient := u3 / v3
		next_v1 := u1 - quotient * v1
		next_v2 := u2 - quotient * v2
		next_v3 := u3 - quotient * v3
		u1 = v1; u2 = v2; u3 = v3
		v1 = next_v1; v2 = next_v2; v3 = next_v3
	}
	return u1 % modulus
}

fn hash_i64(hash_input u64, value i64) u64 {
	mut hash := hash_input
	bits := u64(value)
	for byte in 0 .. 8 {
		byte_value := (bits >> u64(byte * 8)) & u64(255)
		hash = (hash ^ byte_value) * fnv_prime
	}
	return hash
}

@[export: 'rsa_key_generator']
pub fn rsa_key_generator(packed &i64, length usize) i64 {
	unsafe {
		if packed == nil || length < 2 || length > max_packed_length { return invalid_result }
		key_size, draw_count := packed[0], packed[1]
		if key_size < min_key_size || key_size > max_key_size || draw_count < 0 || draw_count > max_draws ||
			length != usize(2 + draw_count) { return invalid_result }
		draw_limit := i64(1) << key_size
		for i in 0 .. int(draw_count) { value := packed[2 + i]; if value < 2 || value >= draw_limit { return invalid_result } }
		mut cursor := usize(2)
		p := rsa_key_generator_generate_large_prime(key_size, packed, length, mut cursor) or { return invalid_result }
		q := rsa_key_generator_generate_large_prime(key_size, packed, length, mut cursor) or { return invalid_result }
		n := p * q
		phi := (p - 1) * (q - 1)
		low := i64(1) << (key_size - 1)
		high := i64(1) << key_size
		mut e := i64(0)
		for {
			e = rsa_key_generator_draw(packed, length, mut cursor, low, high) or { return invalid_result }
			if gcd_i64(e, phi) == 1 { break }
		}
		d := find_mod_inverse(e, phi)
		mut hash := fnv_offset_basis
		hash = hash_i64(hash, n)
		hash = hash_i64(hash, e)
		hash = hash_i64(hash, n)
		hash = hash_i64(hash, d)
		return i64(hash & low63_mask)
	}
}
