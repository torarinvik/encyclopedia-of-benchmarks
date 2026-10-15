package alpha_numerical_sort

import "core:c"

is_digit :: proc "contextless" (value: i64) -> bool { return value >= 48 && value <= 57 }
valid_string :: proc "contextless" (input: [^]i64, start, count: int) -> bool {
	for i := 0; i < count; i += 1 {
		value := input[start + i]
		if !is_digit(value) && (value < 97 || value > 122) do return false
		if value == 48 && i > 0 && is_digit(input[start + i - 1]) do return false
	}
	return true
}

@(export)
alpha_numerical_sort :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 0 || input[0] > 64 do return -2
	first_length := int(input[0])
	if c.size_t(1 + first_length) >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64 do return -2
	second_length := int(input[1 + first_length])
	if length != c.size_t(2 + first_length + second_length) || !valid_string(input, 2, first_length) || !valid_string(input, 2 + first_length, second_length) do return -2
	i, j := 0, 0
	for i < first_length && j < second_length {
		a, b := input[2 + i], input[2 + first_length + j]
		if is_digit(a) && is_digit(b) {
			end_a, end_b := i, j
			for end_a < first_length && is_digit(input[2 + end_a]) { end_a += 1 }
			for end_b < second_length && is_digit(input[2 + first_length + end_b]) { end_b += 1 }
			digits_a, digits_b := end_a - i, end_b - j
			if digits_a != digits_b {
				if digits_a < digits_b do return -1
				return 1
			}
			for k := 0; k < digits_a; k += 1 {
				ca, cb := input[2 + i + k], input[2 + first_length + j + k]
				if ca != cb {
					if ca < cb do return -1
					return 1
				}
			}
			i, j = end_a, end_b
		} else {
			if a != b {
				if a < b do return -1
				return 1
			}
			i += 1; j += 1
		}
	}
	if i == first_length && j == second_length do return 0
	if i == first_length do return -1
	return 1
}
