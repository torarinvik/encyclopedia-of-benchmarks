package kl_divergence_loss

import "core:c"
import "core:math"

MAX_COUNT :: 64
SCALE :: 1_000_000.0
EPSILON :: 1e-5
INVALID_RESULT :: -1.0e300

@(export)
kl_divergence_loss :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > 130 do return INVALID_RESULT
	actual_count_value := input[0]
	predicted_count_value := input[1]
	if actual_count_value < 0 || actual_count_value > MAX_COUNT || predicted_count_value < 0 || predicted_count_value > MAX_COUNT do return INVALID_RESULT
	actual_count := int(actual_count_value)
	predicted_count := int(predicted_count_value)
	if length != c.size_t(2 + actual_count + predicted_count) do return INVALID_RESULT
	for index := 0; index < actual_count; index += 1 {
		if input[2 + index] < 0 || input[2 + index] > 1_000_000 do return INVALID_RESULT
	}
	for index := 0; index < predicted_count; index += 1 {
		if input[2 + actual_count + index] < 0 || input[2 + actual_count + index] > 1_000_000 do return INVALID_RESULT
	}

	paired_count := min(actual_count, predicted_count)
	total := 0.0
	for index := 0; index < paired_count; index += 1 {
		actual := f64(input[2 + index]) / SCALE + EPSILON
		predicted := f64(input[2 + actual_count + index]) / SCALE + EPSILON
		total += actual * math.ln(actual / predicted)
	}
	return total
}
