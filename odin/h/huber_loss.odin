package huber_loss

import "core:c"

SCALE :: i64(1_000_000)
MAX_PAIRS :: i64(64)
MAX_PARSED_PAIRS :: i64(65)
MAX_SAMPLE :: i64(1_000_000_000)
MAX_DELTA :: i64(1_000_000_000)
MAX_INPUT_LENGTH :: c.size_t(133)
INVALID_RESULT :: f64(-1.0e300)

@(export)
huber_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	delta_value, true_count, pred_count := values[0], values[1], values[2]
	if delta_value < 0 || delta_value > MAX_DELTA ||
		true_count < 0 || true_count > MAX_PARSED_PAIRS ||
		pred_count < 0 || pred_count > MAX_PARSED_PAIRS do return INVALID_RESULT
	if length != c.size_t(3 + true_count + pred_count) || true_count != pred_count ||
		pred_count == 0 || true_count > MAX_PAIRS do return INVALID_RESULT

	count := int(true_count)
	for index := 0; index < count * 2; index += 1 {
		if values[3 + index] < -MAX_SAMPLE || values[3 + index] > MAX_SAMPLE do return INVALID_RESULT
	}
	delta := f64(delta_value) / f64(SCALE)
	total_loss := f64(0.0)
	for index := 0; index < count; index += 1 {
		true_value := f64(values[3 + index]) / f64(SCALE)
		predicted_value := f64(values[3 + count + index]) / f64(SCALE)
		residual := true_value - predicted_value
		if residual < 0.0 do residual = -residual
		if residual <= delta do total_loss += 0.5 * (residual * residual)
		else do total_loss += delta * residual - 0.5 * (delta * delta)
	}
	return total_loss / f64(count)
}
