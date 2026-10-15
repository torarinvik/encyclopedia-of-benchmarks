package count_vowels_consonants

import "core:c"

COUNT_BASE :: i64(4_294_967_296)

@(export)
count_vowels_consonants :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 100_000 || (length != 0 && values == nil) do return -1
	vowels: i64 = 0
	consonants: i64 = 0
	for index: c.size_t = 0; index < length; index += 1 {
		code := values[index]
		if code < 0 || code > 127 do return -1
		if (code >= 65 && code <= 90) || (code >= 97 && code <= 122) {
			letter := code | 32
			if letter == 97 || letter == 101 || letter == 105 || letter == 111 || letter == 117 do vowels += 1
			else do consonants += 1
		}
	}
	return vowels * COUNT_BASE + consonants
}
