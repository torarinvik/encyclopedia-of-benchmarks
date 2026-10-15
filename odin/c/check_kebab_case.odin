package check_kebab_case

import "core:c"

MAX_LENGTH :: 4096

is_ascii_word :: proc "contextless" (value: i64) -> bool {
	return (value >= 97 && value <= 122) || (value >= 65 && value <= 90) ||
	       (value >= 48 && value <= 57)
}

@(export)
check_kebab_case :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -2
	}
	for index := 0; index < int(length); index += 1 {
		if values[index] == 95 do return 0
	}
	for index := 1; index + 1 < int(length); index += 1 {
		if values[index] == 45 && is_ascii_word(values[index - 1]) && is_ascii_word(values[index + 1]) do return 1
	}
	return 0
}
