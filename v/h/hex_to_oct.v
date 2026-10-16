module hex_to_oct

const invalid_result = i64(-2147483649)
const i32_modulus = u64(4294967296)

fn hex_digit(code i64) i64 {
	if code >= 48 && code <= 57 { return code - 48 }
	if code >= 65 && code <= 70 { return code - 55 }
	if code >= 97 && code <= 102 { return code - 87 }
	return -1
}

fn signed_i32(bits u64) i64 {
	if bits <= u64(2147483647) { return i64(bits) }
	return i64(bits) - i64(i32_modulus)
}

@[export: 'hex_to_oct']
pub fn hex_to_oct(input &i64, length usize) i64 {
	if length > 8 || (length > 0 && unsafe { input == nil }) { return invalid_result }
	unsafe {
		mut decimal_bits := u64(0)
		for index in 0 .. int(length) {
			digit := hex_digit(input[index])
			if digit < 0 { return invalid_result }
			decimal_bits = (decimal_bits * u64(16) + u64(digit)) % i32_modulus
		}
		mut decimal := signed_i32(decimal_bits)
		if decimal <= 0 { return 0 }

		mut octal_bits := u64(0)
		mut place_value := u64(1)
		for decimal > 0 {
			octal_bits = (octal_bits + u64(decimal % 8) * place_value) % i32_modulus
			decimal /= 8
			place_value = (place_value * u64(10)) % i32_modulus
		}
		return signed_i32(octal_bits)
	}
}
