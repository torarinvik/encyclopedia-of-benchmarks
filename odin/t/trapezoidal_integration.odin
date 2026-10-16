package trapezoidal_integration

import "core:c"

SCALE :: i64(1_000_000)
MAX_ENDPOINT_MICRO :: i64(1_000_000)
MAX_STEPS :: i64(10_000)
INVALID_RESULT :: f64(-1.0e300)

sample_value :: proc(function_id: i64, x: f64) -> f64 {
	if function_id == 0 do return x * x
	return x * x * x
}

@(export)
trapezoidal_integration :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	start_micro, end_micro := values[0], values[1]
	steps, function_id := values[2], values[3]
	if start_micro < -MAX_ENDPOINT_MICRO || start_micro > MAX_ENDPOINT_MICRO ||
		end_micro < -MAX_ENDPOINT_MICRO || end_micro > MAX_ENDPOINT_MICRO ||
		steps < 1 || steps > MAX_STEPS || function_id < 0 || function_id > 1 do return INVALID_RESULT
	start := f64(start_micro) / f64(SCALE)
	end := f64(end_micro) / f64(SCALE)
	delta := (end - start) / f64(steps)
	total := f64(0)
	for index: i64 = 0; index < steps; index += 1 {
		left := start + delta * f64(index)
		right := left + delta
		midpoint := (sample_value(function_id, left) + sample_value(function_id, right)) * 0.5
		total += midpoint * delta
	}
	return total
}
