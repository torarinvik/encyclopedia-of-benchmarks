package cross_entropy_loss

import "core:c"
import "core:math"

MAX_COUNT :: 64
SCALE :: 1_000_000.0

@(export)
cross_entropy_loss :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 do return -1.0e300
	count := values[0]
	if count < 1 || count > MAX_COUNT || length != 1 + 2*c.size_t(count) do return -1.0e300
	terms: [MAX_COUNT]f64
	for i := 0; i < int(count); i += 1 {
		actual_scaled := values[1 + i]
		predicted_scaled := values[1 + int(count) + i]
		if actual_scaled < 0 || actual_scaled > 1_000_000 || predicted_scaled < 1 || predicted_scaled > 1_000_000 do return -1.0e300
		actual := f64(actual_scaled) / SCALE
		predicted := f64(predicted_scaled) / SCALE
		terms[i] = -actual * math.log_f64(predicted)
	}
	total := 0.0
	for i := 0; i < int(count); i += 1 { total += terms[i] }
	return total
}
