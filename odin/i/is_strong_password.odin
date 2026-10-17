package is_strong_password

import "core:c"

MAX_INPUT :: 258

@(export)
is_strong_password :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	minimum_length, text_length_value := input[0], input[1]
	if minimum_length < 0 || minimum_length > 256 || text_length_value < 0 || text_length_value > 256 do return -1
	text_length := int(text_length_value)
	if int(length) != text_length + 2 do return -1

	has_uppercase, has_lowercase, has_digit, has_punctuation := false, false, false, false
	for index := 0; index < text_length; index += 1 {
		value := input[index + 2]
		if value < 0 || value > 127 do return -1
		if value >= 65 && value <= 90 do has_uppercase = true
		if value >= 97 && value <= 122 do has_lowercase = true
		if value >= 48 && value <= 57 do has_digit = true
		if (value >= 33 && value <= 47) || (value >= 58 && value <= 64) ||
			(value >= 91 && value <= 96) || (value >= 123 && value <= 126) do has_punctuation = true
	}

	if text_length_value < minimum_length do return 0
	if has_uppercase && has_lowercase && has_digit && has_punctuation do return 1
	return 0
}
