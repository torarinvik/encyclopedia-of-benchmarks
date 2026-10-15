package average_margin_ranking_loss

import "core:c"

MAX_LENGTH :: 256
INVALID_RESULT :: f64(-1.0e300)

@(export)
average_margin_ranking_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 5 || length > 2 * MAX_LENGTH + 3 do return INVALID_RESULT
	count_value := values[0]
	margin_value := values[1]
	label_value := values[2]
	if count_value < 1 || count_value > MAX_LENGTH || length != c.size_t(2 * count_value + 3) || margin_value < 0 || margin_value > 1000 || (label_value != 1 && label_value != -1) do return INVALID_RESULT
	count := c.size_t(count_value)
	total := f64(0)
	for index := c.size_t(0); index < count; index += 1 {
		first := values[index + 3]
		second := values[index + 3 + count]
		if first < -1000 || first > 1000 || second < -1000 || second > 1000 do return INVALID_RESULT
		loss := f64(margin_value) - f64(label_value) * (f64(first) - f64(second))
		if loss > 0 do total += loss
	}
	return total / f64(count)
}
