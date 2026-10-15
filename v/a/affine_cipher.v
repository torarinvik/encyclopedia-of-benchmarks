module affine_cipher

const max_input_values = 612
const max_text_length = 512

fn gcd_i64(left_value i64, right_value i64) i64 {
	mut left := left_value
	mut right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn inverse_mod(value i64, modulus i64) i64 {
	for candidate := i64(1); candidate < modulus; candidate++ {
		if (value * candidate) % modulus == 1 { return candidate }
	}
	return -1
}

@[export: 'affine_cipher']
pub fn affine_cipher(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 7 || length > max_input_values { return -1 }
		mode := values[0]
		key_a := values[1]
		key_b := values[2]
		alphabet_arg := values[3]
		if mode < 0 || mode > 1 || alphabet_arg < 2 || alphabet_arg > 95 { return -1 }
		alphabet_length := int(alphabet_arg)
		text_length_index := 4 + alphabet_length
		if int(length) <= text_length_index { return -1 }
		text_length_arg := values[text_length_index]
		if key_a < 0 || key_a > 1_000_000 || key_b < 0 || key_b >= alphabet_arg ||
			text_length_arg < 0 || text_length_arg > max_text_length ||
			int(length) != text_length_index + 1 + int(text_length_arg) ||
			gcd_i64(key_a, alphabet_arg) != 1 { return -1 }
		text_length := int(text_length_arg)

		mut positions := [128]i16{init: -1}
		for index in 0 .. alphabet_length {
			symbol := values[4 + index]
			if symbol < 32 || symbol > 126 { return -1 }
			symbol_index := int(symbol)
			if positions[symbol_index] != -1 { return -1 }
			positions[symbol_index] = i16(index)
		}
		for index in 0 .. text_length {
			symbol := values[text_length_index + 1 + index]
			if symbol < 32 || symbol > 126 || positions[int(symbol)] < 0 { return -1 }
		}
		if text_length > int(output_capacity) || (text_length != 0 && output == nil) { return -2 }

		multiplier := key_a % alphabet_arg
		mut inverse := i64(0)
		if mode == 1 { inverse = inverse_mod(multiplier, alphabet_arg) }
		for index in 0 .. text_length {
			symbol := values[text_length_index + 1 + index]
			position := i64(positions[int(symbol)])
			mut mapped := (position * multiplier + key_b) % alphabet_arg
			if mode == 1 { mapped = (((position - key_b + alphabet_arg) % alphabet_arg) * inverse) % alphabet_arg }
			output[index] = u8(values[4 + int(mapped)])
		}
		return i64(text_length)
	}
}
