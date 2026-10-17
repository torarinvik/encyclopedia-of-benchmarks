package mixed_keyword_cypher

import "core:c"

MAX_KEYWORD_LENGTH :: 64
MAX_PLAINTEXT_LENGTH :: 512
MAX_INPUT_LENGTH :: 578

@(export)
mixed_keyword_cypher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	raw_keyword_length := input[0]
	if raw_keyword_length < 1 || raw_keyword_length > i64(MAX_KEYWORD_LENGTH) do return -1
	keyword_length := int(raw_keyword_length)
	plaintext_length_index := 1 + keyword_length
	if plaintext_length_index >= int(length) do return -1

	raw_plaintext_length := input[plaintext_length_index]
	if raw_plaintext_length < 0 || raw_plaintext_length > i64(MAX_PLAINTEXT_LENGTH) do return -1
	plaintext_length := int(raw_plaintext_length)
	if int(length) != plaintext_length_index + 1 + plaintext_length do return -1

	unique_letters: [26]u8
	seen: [26]bool
	for index := 0; index < 26; index += 1 { seen[index] = false }
	unique_count := 0
	for index := 0; index < keyword_length; index += 1 {
		raw := input[1+index]
		if raw < 0 || raw > 127 do return -1
		letter := int(raw)
		if letter >= 'a' && letter <= 'z' do letter -= 'a' - 'A'
		if letter >= 'A' && letter <= 'Z' {
			alphabet_index := letter - 'A'
			if !seen[alphabet_index] {
				seen[alphabet_index] = true
				unique_letters[unique_count] = u8(letter)
				unique_count += 1
			}
		}
	}
	if unique_count == 0 do return -1

	for index := 0; index < plaintext_length; index += 1 {
		raw := input[plaintext_length_index+1+index]
		if raw < 0 || raw > 127 do return -1
	}

	shifted: [26]u8
	for index := 0; index < unique_count; index += 1 { shifted[index] = unique_letters[index] }
	shifted_count := unique_count
	for index := 0; index < 26; index += 1 {
		if !seen[index] {
			shifted[shifted_count] = u8('A' + index)
			shifted_count += 1
		}
	}

	mapping: [26]u8
	alphabet_index := 0
	for column := 0; column < unique_count; column += 1 {
		for row_start := 0; row_start < 26; row_start += unique_count {
			shifted_index := row_start + column
			if shifted_index >= 26 do break
			mapping[alphabet_index] = shifted[shifted_index]
			alphabet_index += 1
		}
	}

	buffer: [MAX_PLAINTEXT_LENGTH]u8
	for index := 0; index < plaintext_length; index += 1 {
		letter := int(input[plaintext_length_index+1+index])
		if letter >= 'a' && letter <= 'z' do letter -= 'a' - 'A'
		if letter >= 'A' && letter <= 'Z' {
			buffer[index] = mapping[letter-'A']
		} else {
			buffer[index] = u8(letter)
		}
	}

	if output == nil || capacity < c.size_t(plaintext_length) do return -2
	for index := 0; index < plaintext_length; index += 1 do output[index] = buffer[index]
	return i64(plaintext_length)
}
