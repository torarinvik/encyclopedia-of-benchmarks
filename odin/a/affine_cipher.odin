package affine_cipher

import "core:c"

MAX_INPUT_VALUES :: 612
MAX_TEXT_LENGTH :: 512

gcd_i64 :: proc "contextless" (left_value, right_value: i64) -> i64 {
	left, right := left_value, right_value
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

inverse_mod :: proc "contextless" (value, modulus: i64) -> i64 {
	for candidate: i64 = 1; candidate < modulus; candidate += 1 {
		if (value * candidate) % modulus == 1 do return candidate
	}
	return -1
}

@(export)
affine_cipher :: proc "contextless" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 7 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	mode, key_a, key_b, alphabet_arg := values[0], values[1], values[2], values[3]
	if mode < 0 || mode > 1 || alphabet_arg < 2 || alphabet_arg > 95 do return -1
	alphabet_length := int(alphabet_arg)
	text_length_index := 4 + alphabet_length
	if int(length) <= text_length_index do return -1
	text_length_arg := values[text_length_index]
	if key_a < 0 || key_a > 1_000_000 || key_b < 0 || key_b >= alphabet_arg ||
		text_length_arg < 0 || text_length_arg > MAX_TEXT_LENGTH ||
		int(length) != text_length_index + 1 + int(text_length_arg) ||
		gcd_i64(key_a, alphabet_arg) != 1 {
		return -1
	}
	text_length := int(text_length_arg)

	positions: [128]int = {}
	for code := 0; code < 128; code += 1 do positions[code] = -1
	for index := 0; index < alphabet_length; index += 1 {
		symbol := values[4 + index]
		if symbol < 32 || symbol > 126 do return -1
		symbol_index := int(symbol)
		if positions[symbol_index] != -1 do return -1
		positions[symbol_index] = index
	}
	for index := 0; index < text_length; index += 1 {
		symbol := values[text_length_index + 1 + index]
		if symbol < 32 || symbol > 126 || positions[int(symbol)] < 0 do return -1
	}
	if text_length > int(output_capacity) do return -2

	multiplier := key_a % alphabet_arg
	inverse: i64 = 0
	if mode == 1 do inverse = inverse_mod(multiplier, alphabet_arg)
	for index := 0; index < text_length; index += 1 {
		symbol := values[text_length_index + 1 + index]
		position := i64(positions[int(symbol)])
		mapped := (position * multiplier + key_b) % alphabet_arg
		if mode == 1 do mapped = (((position - key_b + alphabet_arg) % alphabet_arg) * inverse) % alphabet_arg
		output[index] = u8(values[4 + int(mapped)])
	}
	return i64(text_length)
}
