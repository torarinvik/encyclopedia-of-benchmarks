package rc4

import "core:c"

MAX_KEY_LENGTH :: 256
MAX_PLAINTEXT_LENGTH :: 256
MAX_INPUT_VALUES :: 515

@(export)
rc4 :: proc "c" (input: [^]i64, length: c.size_t,
                   output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	key_length_value := input[0]
	plaintext_length_value := input[1]
	if key_length_value < 1 || key_length_value > MAX_KEY_LENGTH do return -1
	if plaintext_length_value < 0 || plaintext_length_value > MAX_PLAINTEXT_LENGTH do return -1
	key_length := int(key_length_value)
	plaintext_length := int(plaintext_length_value)
	if length != c.size_t(2 + key_length + plaintext_length) do return -1
	for index := 0; index < key_length + plaintext_length; index += 1 {
		value := input[2 + index]
		if value < 0 || value > 255 do return -1
	}
	if plaintext_length == 0 do return 0
	if output == nil || capacity < c.size_t(plaintext_length) do return -2

	var state: [256]u8
	for index := 0; index < 256; index += 1 { state[index] = u8(index) }
	j := 0
	for index := 0; index < 256; index += 1 {
		j = (j + int(state[index]) + int(input[2 + index % key_length])) % 256
		temporary := state[index]
		state[index] = state[j]
		state[j] = temporary
	}

	i := 0
	j = 0
	for offset := 0; offset < plaintext_length; offset += 1 {
		i = (i + 1) % 256
		j = (j + int(state[i])) % 256
		temporary := state[i]
		state[i] = state[j]
		state[j] = temporary
		stream_index := (int(state[i]) + int(state[j])) % 256
		output[offset] = u8(input[2 + key_length + offset]) ^ state[stream_index]
	}
	return i64(plaintext_length)
}
