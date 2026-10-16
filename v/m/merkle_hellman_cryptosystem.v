module main

fn gcd_u64(a_value u64, b_value u64) u64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn add_mod(a u64, b u64, modulus u64) u64 {
	return if a >= modulus - b { a - (modulus - b) } else { a + b }
}

fn mul_mod(a_value u64, b_value u64, modulus u64) u64 {
	mut a := a_value % modulus
	mut b := b_value
	mut result := u64(0)
	for b != 0 {
		if (b & u64(1)) != 0 { result = add_mod(result, a, modulus) }
		b >>= 1
		if b != 0 { a = add_mod(a, a, modulus) }
	}
	return result
}

fn inverse_mod(value u64, modulus u64) u64 {
	mut old_r := modulus
	mut r := value % modulus
	mut old_t := u64(0)
	mut t := u64(1)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r % r
		product := mul_mod(quotient % modulus, t, modulus)
		next_t := if old_t >= product { old_t - product } else { modulus - (product - old_t) }
		old_r = r
		r = next_r
		old_t = t
		t = next_t
	}
	return old_t
}

fn put_i64_le(output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'merkle_hellman_cryptosystem']
pub fn merkle_hellman_cryptosystem(input &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(input) || length < 12 || length > 43 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 127 || input[10] < 1 || input[10] > 32 { return -1 }
		draw_count := int(input[10])
		if length != usize(11 + draw_count) { return -1 }

		mut easy := [8]u64{}
		mut total := u64(1) << 32
		for index in 0 .. 8 {
			if input[1 + index] < 0 || input[1 + index] > 4_294_967_295 { return -1 }
			easy[index] = total + u64(input[1 + index])
			total += easy[index]
		}
		if input[9] < 0 || input[9] > 4_294_967_295 { return -1 }
		modulus := total + u64(input[9])
		for index in 0 .. draw_count {
			draw_value := input[11 + index]
			if draw_value < 0 || u64(draw_value) > modulus { return -1 }
			divisor := gcd_u64(u64(draw_value), modulus)
			if index + 1 < draw_count && divisor == 1 { return -1 }
			if index + 1 == draw_count && divisor != 1 { return -1 }
		}
		if isnil(output) || capacity < 17 { return -2 }

		multiplier := u64(input[10 + draw_count])
		mut hard := [8]u64{}
		for index in 0 .. 8 { hard[index] = mul_mod(multiplier, easy[index], modulus) }
		message := u64(input[0])
		mut ciphertext := u64(0)
		for bit_index := 7; bit_index >= 0; bit_index-- {
			if ((message >> bit_index) & 1) != 0 {
				ciphertext += hard[7 - bit_index]
			}
		}

		inverse := inverse_mod(multiplier, modulus)
		mut residue := mul_mod(inverse, ciphertext % modulus, modulus)
		mut decoded := u8(0)
		for index in 0 .. 8 {
			weight := easy[7 - index]
			if residue >= weight {
				residue -= weight
				decoded |= u8(1 << index)
			}
		}
		if residue != 0 || u64(decoded) != message { return -1 }
		put_i64_le(output, 0, i64(ciphertext))
		put_i64_le(output, 8, 1)
		unsafe { output[16] = decoded }
		return 17
	}
}
