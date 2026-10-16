module hex_to_bin

const invalid_result = i64(-9223372036854775808)

fn hex_digit(byte i64) i64 {
	if byte >= 48 && byte <= 57 { return byte - 48 }
	if byte >= 65 && byte <= 70 { return byte - 65 + 10 }
	if byte >= 97 && byte <= 102 { return byte - 97 + 10 }
	return -1
}

@[export: 'hex_to_bin']
pub fn hex_to_bin(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > 5 { return invalid_result }
		mut start := 0
		mut sign := i64(1)
		if input[0] == 45 {
			sign = -1
			start = 1
		}
		if int(length) - start < 1 || int(length) - start > 4 { return invalid_result }

		mut value := i64(0)
		for index in start .. int(length) {
			digit := hex_digit(input[index])
			if digit < 0 { return invalid_result }
			value = value * 16 + digit
		}
		if value == 0 { return invalid_result }

		mut decimal_binary_digits := i64(0)
		mut place := i64(1)
		for value > 0 {
			decimal_binary_digits += (value % 2) * place
			value /= 2
			if value > 0 { place *= 10 }
		}
		return sign * decimal_binary_digits
	}
}
