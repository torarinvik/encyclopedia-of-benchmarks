package rsa_key_generator

import "core:c"

INVALID_RESULT :: i64 = -1
MIN_KEY_SIZE :: i64 = 2
MAX_KEY_SIZE :: i64 = 20
MAX_DRAWS :: i64 = 1024
MAX_PACKED_LENGTH :: c.size_t = 1027
FNV_OFFSET_BASIS :: u64 = 14695981039346656037
FNV_PRIME :: u64 = 1099511628211
LOW_63_MASK :: u64 = 0x7fffffffffffffff

Draw_State :: struct {
	values: [^]i64,
	length: c.size_t,
	cursor: c.size_t,
	key_size: i64,
	failed: bool,
}

next_draw :: proc "contextless" (state: ^Draw_State, low, high: i64, result: ^i64) -> bool {
	if state.cursor >= state.length { state.failed = true; return false }
	value := state.values[state.cursor]
	state.cursor += 1
	if value < low || value >= high { state.failed = true; return false }
	result^ = value
	return true
}

gcd_i64 :: proc "contextless" (a_input, b_input: i64) -> i64 {
	a, b := a_input, b_input
	for b != 0 { remainder := a % b; a = b; b = remainder }
	if a < 0 do return -a
	return a
}

power_mod_i64 :: proc "contextless" (base, exponent_input, modulus: i64) -> i64 {
	exponent := exponent_input
	result := i64(1)
	power := base % modulus
	for exponent > 0 {
		if exponent&1 != 0 do result = (result * power) % modulus
		power = (power * power) % modulus
		exponent /= 2
	}
	return result
}

rabin_miller :: proc "contextless" (num: i64, state: ^Draw_State) -> bool {
	s, t := num-1, i64(0)
	for s%2 == 0 { s /= 2; t += 1 }
	for round := 0; round < 5; round += 1 {
		base: i64
		if !next_draw(state, 2, num-1, &base) do return false
		value := power_mod_i64(base, s, num)
		if value != 1 {
			i := i64(0)
			for value != num-1 {
				if i == t-1 do return false
				i += 1
				value = (value * value) % num
			}
		}
	}
	return true
}

is_prime_low_num :: proc "contextless" (num: i64, state: ^Draw_State) -> bool {
	if num < 2 do return false
	if num <= 997 {
		for divisor := i64(2); divisor*divisor <= num; divisor += 1 {
			if num%divisor == 0 do return false
		}
		return true
	}
	for divisor := i64(2); divisor <= 997; divisor += 1 {
		if num%divisor == 0 do return false
	}
	return rabin_miller(num, state)
}

generate_large_prime :: proc "contextless" (state: ^Draw_State, prime: ^i64) -> bool {
	low := i64(1) << (state.key_size-1)
	high := i64(1) << state.key_size
	for !state.failed {
		candidate: i64
		if !next_draw(state, low, high, &candidate) do return false
		if is_prime_low_num(candidate, state) { prime^ = candidate; return true }
	}
	return false
}

find_mod_inverse :: proc "contextless" (a, modulus: i64) -> i64 {
	if gcd_i64(a, modulus) != 1 do return INVALID_RESULT
	u1, u2, u3 := i64(1), i64(0), a
	v1, v2, v3 := i64(0), i64(1), modulus
	for v3 != 0 {
		quotient := u3 / v3
		next_v1 := u1 - quotient*v1
		next_v2 := u2 - quotient*v2
		next_v3 := u3 - quotient*v3
		u1, u2, u3 = v1, v2, v3
		v1, v2, v3 = next_v1, next_v2, next_v3
	}
	return u1 % modulus
}

hash_i64 :: proc "contextless" (hash_input: u64, value: i64) -> u64 {
	hash := hash_input
	bits := transmute(u64(value))
	for byte := 0; byte < 8; byte += 1 {
		hash = (hash ^ u64(u8(bits >> u64(byte*8)))) * FNV_PRIME
	}
	return hash
}

@(export)
rsa_key_generator :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 2 || length > MAX_PACKED_LENGTH do return INVALID_RESULT
	key_size, draw_count := packed[0], packed[1]
	if key_size < MIN_KEY_SIZE || key_size > MAX_KEY_SIZE || draw_count < 0 || draw_count > MAX_DRAWS ||
		length != c.size_t(2+draw_count) do return INVALID_RESULT
	draw_limit := i64(1) << key_size
	for i := c.size_t(0); i < c.size_t(draw_count); i += 1 {
		if packed[2+i] < 2 || packed[2+i] >= draw_limit do return INVALID_RESULT
	}

	state := Draw_State{values=packed, length=length, cursor=2, key_size=key_size, failed=false}
	p, q: i64
	if !generate_large_prime(&state, &p) || !generate_large_prime(&state, &q) do return INVALID_RESULT
	n := p*q
	phi := (p-1)*(q-1)
	low := i64(1) << (key_size-1)
	high := i64(1) << key_size
	e: i64
	for {
		if !next_draw(&state, low, high, &e) do return INVALID_RESULT
		if gcd_i64(e, phi) == 1 do break
	}
	d := find_mod_inverse(e, phi)
	hash := FNV_OFFSET_BASIS
	hash = hash_i64(hash, n)
	hash = hash_i64(hash, e)
	hash = hash_i64(hash, n)
	hash = hash_i64(hash, d)
	return i64(hash & LOW_63_MASK)
}
