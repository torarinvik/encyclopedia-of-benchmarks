package merkle_hellman_cryptosystem

import "core:c"

gcd_u64 :: proc "contextless" (a_value, b_value: u64) -> u64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

add_mod :: proc "contextless" (a, b, modulus: u64) -> u64 {
	if a >= modulus - b do return a - (modulus - b)
	return a + b
}

mul_mod :: proc "contextless" (a_value, b_value, modulus: u64) -> u64 {
	a := a_value % modulus
	b := b_value
	result := u64(0)
	for b != 0 {
		if (b & 1) != 0 do result = add_mod(result, a, modulus)
		b >>= 1
		if b != 0 do a = add_mod(a, a, modulus)
	}
	return result
}

inverse_mod :: proc "contextless" (value, modulus: u64) -> u64 {
	old_r, r := modulus, value % modulus
	old_t, t := u64(0), u64(1)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r % r
		product := mul_mod(quotient % modulus, t, modulus)
		next_t := old_t - product
		if old_t < product do next_t = modulus - (product - old_t)
		old_r, r = r, next_r
		old_t, t = t, next_t
	}
	return old_t
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

@(export)
merkle_hellman_cryptosystem :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 12 || length > 43 do return -1
	if input[0] < 0 || input[0] > 127 || input[10] < 1 || input[10] > 32 do return -1
	draw_count := int(input[10])
	if int(length) != 11 + draw_count do return -1

	easy: [8]u64
	total := u64(1) << 32
	for index := 0; index < 8; index += 1 {
		if input[1+index] < 0 || input[1+index] > 4294967295 do return -1
		easy[index] = total + u64(input[1+index])
		total += easy[index]
	}
	if input[9] < 0 || input[9] > 4294967295 do return -1
	modulus := total + u64(input[9])
	for index := 0; index < draw_count; index += 1 {
		draw_value := input[11+index]
		if draw_value < 0 || u64(draw_value) > modulus do return -1
		divisor := gcd_u64(u64(draw_value), modulus)
		if index+1 < draw_count && divisor == 1 do return -1
		if index+1 == draw_count && divisor != 1 do return -1
	}
	if output == nil || capacity < 17 do return -2

	multiplier := u64(input[10+draw_count])
	hard: [8]u64
	for index := 0; index < 8; index += 1 { hard[index] = mul_mod(multiplier, easy[index], modulus) }
	message := u64(input[0])
	ciphertext := u64(0)
	for bit_index := 7; bit_index >= 0; bit_index -= 1 {
		if ((message >> u64(bit_index)) & 1) != 0 do ciphertext += hard[7-bit_index]
	}

	inverse := inverse_mod(multiplier, modulus)
	residue := mul_mod(inverse, ciphertext%modulus, modulus)
	decoded := u8(0)
	for index := 0; index < 8; index += 1 {
		weight := easy[7-index]
		if residue >= weight {
			residue -= weight
			decoded |= u8(1 << u64(index))
		}
	}
	if residue != 0 || u64(decoded) != message do return -1
	put_i64_le(output, 0, i64(ciphertext))
	put_i64_le(output, 8, 1)
	output[16] = decoded
	return 17
}
