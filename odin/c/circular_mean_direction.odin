package circular_mean_direction

import "core:c"
import "core:math"

PI_VALUE :: 3.14159265358979323846264338327950288
TAU_VALUE :: 6.28318530717958647692528676655900576
MAX_N :: 64
CUTOFF_SCALE :: 0.0000000037252902984619140625

wrap_angle :: proc "contextless" (angle: f64) -> f64 {
	value := angle - math.floor_f64((angle + PI_VALUE) / TAU_VALUE) * TAU_VALUE
	if value >= PI_VALUE do value -= TAU_VALUE
	if value < -PI_VALUE do value += TAU_VALUE
	return value
}

@(export)
circular_mean_direction :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 66 do return -1
	count_value := input[0]
	if !math.is_finite(count_value) || math.floor_f64(count_value) != count_value ||
		count_value < 1.0 || count_value > f64(MAX_N) do return -1
	count := int(count_value)
	if length != c.size_t(count + 1) do return -1

	sum_cos, sum_sin: f64 = 0.0, 0.0
	correction_cos, correction_sin: f64 = 0.0, 0.0
	for index := 0; index < count; index += 1 {
		raw := input[index + 1]
		if !math.is_finite(raw) || math.abs(raw) > 8.0 * PI_VALUE do return -1
		angle := wrap_angle(raw)
		adjusted_cos := math.cos_f64(angle) - correction_cos
		next_cos := sum_cos + adjusted_cos
		correction_cos = (next_cos - sum_cos) - adjusted_cos
		sum_cos = next_cos
		adjusted_sin := math.sin_f64(angle) - correction_sin
		next_sin := sum_sin + adjusted_sin
		correction_sin = (next_sin - sum_sin) - adjusted_sin
		sum_sin = next_sin
	}
	resultant := math.sqrt_f64(sum_cos * sum_cos + sum_sin * sum_sin)
	if !math.is_finite(resultant) || resultant <= f64(count) * CUTOFF_SCALE do return -1
	if output == nil || capacity < 1 do return -2
	output[0] = wrap_angle(math.atan2(sum_sin, sum_cos))
	return 1
}
