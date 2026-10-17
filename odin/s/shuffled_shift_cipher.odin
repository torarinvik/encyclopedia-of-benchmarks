package shuffled_shift_cipher

import "core:c"

MAX_PASSCODE_LENGTH :: 20
MAX_TEXT_LENGTH :: 256
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(279)
ALPHABET_LENGTH :: 97

is_ascii_alphanumeric :: proc "contextless" (value: i64) -> bool {
	return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

shuffled_shift_cipher :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	pass_length_value, text_length_value := input[0], input[1]
	if pass_length_value < 1 || pass_length_value > MAX_PASSCODE_LENGTH || text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
	pass_length, text_length := int(pass_length_value), int(text_length_value)
	if input_length != c.size_t(2+pass_length+text_length) do return -1

	var passcode: [MAX_PASSCODE_LENGTH]u8
	for index in 0..<pass_length {
		value := input[index+2]
		if !is_ascii_alphanumeric(value) do return -1
		passcode[index] = u8(value)
	}
	text_start := 2+pass_length
	var plaintext: [MAX_TEXT_LENGTH]u8
	for index in 0..<text_length {
		value := input[text_start+index]
		if !((value >= 32 && value <= 126) || value == 9 || value == 10) do return -1
		plaintext[index] = u8(value)
	}
	if output == nil || output_capacity < c.size_t(text_length) do return -2

	var breakpoints: [128]bool
	shift_sum := i64(0)
	for index in 0..<pass_length {
		byte := passcode[index]
		breakpoints[int(byte)] = true
		if index%2 == 0 { shift_sum += i64(byte) } else { shift_sum -= i64(byte) }
	}
	shift := pass_length
	if shift_sum > 0 { shift = int(shift_sum) }

	var alphabet: [ALPHABET_LENGTH]u8
	alphabet_length := 0
	for value in 97..<123 { alphabet[alphabet_length] = u8(value); alphabet_length += 1 }
	for value in 65..<91 { alphabet[alphabet_length] = u8(value); alphabet_length += 1 }
	for value in 48..<58 { alphabet[alphabet_length] = u8(value); alphabet_length += 1 }
	for value in 33..<127 {
		if !is_ascii_alphanumeric(i64(value)) { alphabet[alphabet_length] = u8(value); alphabet_length += 1 }
	}
	alphabet[alphabet_length] = 32; alphabet_length += 1
	alphabet[alphabet_length] = 9; alphabet_length += 1
	alphabet[alphabet_length] = 10; alphabet_length += 1

	var key: [ALPHABET_LENGTH]u8
	var segment: [ALPHABET_LENGTH]u8
	key_length, segment_length := 0, 0
	for index in 0..<alphabet_length {
		byte := alphabet[index]
		segment[segment_length] = byte
		segment_length += 1
		if breakpoints[int(byte)] || index+1 == alphabet_length {
			for segment_length > 0 {
				segment_length -= 1
				key[key_length] = segment[segment_length]
				key_length += 1
			}
		}
	}

	for index in 0..<text_length {
		key_index := 0
		for key_index < key_length && key[key_index] != plaintext[index] { key_index += 1 }
		output[index] = key[(key_index+shift)%ALPHABET_LENGTH]
	}
	return i64(text_length)
}
