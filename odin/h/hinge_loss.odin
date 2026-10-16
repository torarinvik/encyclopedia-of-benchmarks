package hinge_loss

import "core:c"

MAX_COUNT :: 256
MAX_INPUT_LENGTH :: 1 + 2 * MAX_COUNT
PREDICTION_SCALE :: f64 = 1_000_000.0
INVALID_RESULT :: f64 = -1.0e300

@(export)
hinge_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	count_value := values[0]
	if count_value < 1 || count_value > MAX_COUNT do return INVALID_RESULT
	count := usize(count_value)
	if length != c.size_t(1 + 2 * count) do return INVALID_RESULT

	total := f64(0.0)
	for index: usize = 0; index < count; index += 1 {
		label := values[1 + index]
		score_scaled := values[1 + count + index]
		if (label != -1 && label != 1) || score_scaled < -1_000_000 || score_scaled > 1_000_000 do return INVALID_RESULT
		prediction := f64(score_scaled) / PREDICTION_SCALE
		loss := 1.0 - f64(label) * prediction
		if loss > 0.0 do total += loss
	}
	return total / f64(count)
}
