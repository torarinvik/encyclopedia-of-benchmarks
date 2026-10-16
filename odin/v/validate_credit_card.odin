package validate_credit_card

import "core:c"

MAX_TEXT_LENGTH :: 64

@(export)
validate_credit_card :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_TEXT_LENGTH + 1 do return -1
	n := input[0]
	if n < 0 || n > MAX_TEXT_LENGTH || length != c.size_t(n + 1) do return -1
	for i := 0; i < int(n); i += 1 {
		if input[i + 1] < 0 || input[i + 1] > 127 do return -1
	}
	if n < 13 || n > 16 do return 0
	for i := 0; i < int(n); i += 1 {
		if input[i + 1] < 48 || input[i + 1] > 57 do return 0
	}
	first := input[1] - 48
	second := input[2] - 48
	if !(first == 4 || first == 5 || first == 6 ||
		(first == 3 && (second == 4 || second == 5 || second == 7))) do return 0
	total: i64 = 0
	for i := 0; i < int(n); i += 1 {
		digit := input[i + 1] - 48
		if i % 2 == 0 {
			digit *= 2
			if digit > 9 do digit -= 9
		}
		total += digit
	}
	if total % 10 == 0 do return 1
	return 0
}
