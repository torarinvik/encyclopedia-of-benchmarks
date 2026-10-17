package key_finder

import "core:c"

MAX_TEXT_LENGTH :: i64(256)
MAX_INPUT_LENGTH :: c.size_t(258)
WORD_BANK :: [24]string{
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be ",
}

shift_ascii_letter :: proc "contextless" (code, key: i64) -> i64 {
	if code >= 65 && code <= 90 do return 65 + (code - 65 + key) % 26
	if code >= 97 && code <= 122 do return 97 + (code - 97 + key) % 26
	return code
}

@(export)
key_finder :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	text_length_value := input[0]
	if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH do return -1
	text_length := int(text_length_value)
	if int(length) != text_length + 1 do return -1
	for index := 0; index < text_length; index += 1 {
		code := input[index + 1]
		if code < 32 || code > 126 || (code >= 48 && code <= 57) do return -1
	}

	for key := 0; key < 26; key += 1 {
		key_value := i64(key)
		for start := 0; start < text_length; start += 1 {
			for phrase in WORD_BANK {
				phrase_length := len(phrase)
				if start + phrase_length > text_length do continue
				offset := 0
				for offset < phrase_length {
					if shift_ascii_letter(input[start + offset + 1], key_value) != i64(phrase[offset]) do break
					offset += 1
				}
				if offset == phrase_length do return key_value
			}
		}
	}
	return 0
}
