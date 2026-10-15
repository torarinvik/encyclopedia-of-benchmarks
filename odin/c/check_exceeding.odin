package check_exceeding

import "core:c"

MAX_LENGTH :: 4096

// Check nondecreasing letter gaps after ASCII normalization and filtering.
@(export)
check_exceeding :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 32 || value > 126 do return -2
	}

	previous_letter: int = -1
	previous_gap: int = -1
	for index := 0; index < int(length); index += 1 {
		letter := int(values[index])
		if letter >= 97 && letter <= 122 do letter -= 32
		if letter < 65 || letter > 90 do continue
		if previous_letter >= 0 && letter != previous_letter {
			gap := abs(letter - previous_letter)
			if previous_gap >= 0 && gap < previous_gap do return 0
			previous_gap = gap
		}
		previous_letter = letter
	}
	return 1
}
