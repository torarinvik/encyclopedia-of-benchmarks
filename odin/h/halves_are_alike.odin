package halves_are_alike

import "core:c"

// Compare the vowel counts in two equal ASCII-letter halves.
@(export)
halves_are_alike :: proc "c" (letters: [^]i64, length: c.size_t) -> i64 {
	if length > 256 || length % 2 != 0 do return -1
	half := int(length / 2)
	first := 0
	second := 0
	for index := 0; index < int(length); index += 1 {
		value := letters[index]
		if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) do return -1
		vowel := value == 97 || value == 101 || value == 105 || value == 111 || value == 117 ||
			value == 65 || value == 69 || value == 73 || value == 79 || value == 85
		if vowel {
			if index < half { first += 1 }
			else { second += 1 }
		}
	}
	if first == second { return 1 }
	return 0
}
