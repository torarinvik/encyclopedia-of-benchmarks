package negative_log_likelihood

import "core:c"
import "core:math"

MAX_COUNT :: 64
SCALE :: 1_000_000.0

@(export)
negative_log_likelihood :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 do return -1.0e300
	count := values[0]
	if count < 1 || count > MAX_COUNT || length != 1 + 2*c.size_t(count) do return -1.0e300
	total := 0.0
	for i := 0; i < int(count); i += 1 {
		actual_scaled := values[1 + i]
		predicted_scaled := values[1 + int(count) + i]
		if actual_scaled < 0 || actual_scaled > 1_000_000 || predicted_scaled < 1 || predicted_scaled > 999_999 do return -1.0e300
		actual := f64(actual_scaled) / SCALE
		predicted := f64(predicted_scaled) / SCALE
		total += -actual * math.log_f64(predicted) - (1.0 - actual) * math.log_f64(1.0 - predicted)
	}
	return total / f64(count)
}
