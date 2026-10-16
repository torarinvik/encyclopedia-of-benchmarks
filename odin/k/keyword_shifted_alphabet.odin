package keyword_shifted_alphabet

import "core:c"

MAX_KEYWORD_LENGTH :: 26
MAX_MESSAGE_LENGTH :: 512
MAX_INPUT_LENGTH :: 3 + MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 1

@(export)
keyword_shifted_alphabet :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return -1
	operation := input[0]
	keyword_length_value := input[1]
	message_length_value := input[2]
	if (operation != 0 && operation != 1) || keyword_length_value < 1 || keyword_length_value > 26 ||
		message_length_value < 1 || message_length_value > MAX_MESSAGE_LENGTH do return -1
	keyword_length := int(keyword_length_value)
	message_length := int(message_length_value)
	if int(length) != 3 + keyword_length + message_length do return -1

	keyword: [MAX_KEYWORD_LENGTH]u8 = {}
	seen: [26]bool = {}
	for i in 0..<keyword_length {
		value := input[3 + i]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
		lower := u8(if value >= 65 && value <= 90 then value + 32 else value)
		index := int(lower - 'a')
		if seen[index] do return -1
		seen[index] = true
		keyword[i] = lower
	}
	message: [MAX_MESSAGE_LENGTH]u8 = {}
	for i in 0..<message_length {
		value := input[3 + keyword_length + i]
		if value < 0 || value > 127 do return -1
		message[i] = u8(value)
	}

	cipher_alphabet: [26]u8 = {}
	encode: [26]u8 = {}
	decode: [26]u8 = {}
	cipher_length := 0
	for i in 0..<keyword_length { cipher_alphabet[cipher_length] = keyword[i]; cipher_length += 1 }
	for i in 0..<26 {
		letter := u8('a' + i)
		if !seen[i] { cipher_alphabet[cipher_length] = letter; cipher_length += 1 }
	}
	for i in 0..<26 {
		encode[i] = cipher_alphabet[i]
		decode[int(cipher_alphabet[i] - 'a')] = u8('a' + i)
	}

	if output_capacity < c.size_t(message_length) || output == nil do return -2
	for i in 0..<message_length {
		value := message[i]
		uppercase := value >= 'A' && value <= 'Z'
		mut index := 0
		if uppercase { index = int(value - 'A') }
		else if value >= 'a' && value <= 'z' { index = int(value - 'a') }
		else { output[i] = value; continue }
		translated := if operation == 0 then encode[index] else decode[index]
		output[i] = if uppercase then translated - ('a' - 'A') else translated
	}
	return i64(message_length)
}
