package cosine_similarity

import "core:c"
import "core:math"

MAX_STRING_LENGTH :: 64
MAX_INPUT_LENGTH :: 132
ALPHABET_SIZE :: 95
INVALID_RESULT :: f64(-1.0e300)

@(export)
cosine_similarity :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	if input[0] < 0 || input[0] > MAX_STRING_LENGTH || input[1] < 0 || input[1] > MAX_STRING_LENGTH do return INVALID_RESULT
	left_length := int(input[0])
	right_length := int(input[1])
	if length != c.size_t(2 + left_length + right_length) do return INVALID_RESULT

	var left_counts: [ALPHABET_SIZE]u64 = {}
	var right_counts: [ALPHABET_SIZE]u64 = {}
	for index := 0; index < left_length; index += 1 {
		value := input[2 + index]
		if value < 32 || value > 126 do return INVALID_RESULT
		if value >= 65 && value <= 90 { value += 32 }
		left_counts[int(value - 32)] += 1
	}
	for index := 0; index < right_length; index += 1 {
		value := input[2 + left_length + index]
		if value < 32 || value > 126 do return INVALID_RESULT
		if value >= 65 && value <= 90 { value += 32 }
		right_counts[int(value - 32)] += 1
	}

	dot_product := f64(0)
	left_magnitude_squared := f64(0)
	right_magnitude_squared := f64(0)
	for index := 0; index < ALPHABET_SIZE; index += 1 {
		left := f64(left_counts[index])
		right := f64(right_counts[index])
		dot_product += left * right
		left_magnitude_squared += left * left
		right_magnitude_squared += right * right
	}
	if left_magnitude_squared <= 0 || right_magnitude_squared <= 0 do return 0
	return dot_product / (math.sqrt(left_magnitude_squared) * math.sqrt(right_magnitude_squared))
}
