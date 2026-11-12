package marsaglia_polar_normal

import "core:c"
import "core:math"

MAX_DRAWS :: 128
MAX_ATTEMPTS :: 64
DRAW_SCALE :: 2147483648.0

is_bounded_integer :: proc "contextless" (value, minimum, maximum: f64) -> bool {
	return math.is_finite(value) && math.trunc(value) == value && value >= minimum && value <= maximum
}

@(export)
marsaglia_polar_normal :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 2 + MAX_DRAWS do return -1
	if !is_bounded_integer(input[0], 2.0, f64(MAX_DRAWS)) ||
		!is_bounded_integer(input[1], 1.0, f64(MAX_ATTEMPTS)) do return -1
	draw_count, attempt_cap := int(input[0]), int(input[1])
	if draw_count % 2 != 0 || length != c.size_t(2 + draw_count) || draw_count < 2 * attempt_cap do return -1
	for index := 0; index < draw_count; index += 1 {
		if !is_bounded_integer(input[2 + index], 0.0, 4294967295.0) do return -1
	}

	first, second: f64 = 0.0, 0.0
	accepted := false
	for attempt := 0; attempt < attempt_cap; attempt += 1 {
		u1 := input[2 + 2 * attempt] / DRAW_SCALE - 1.0
		u2 := input[3 + 2 * attempt] / DRAW_SCALE - 1.0
		radius_squared := u1 * u1 + u2 * u2
		if radius_squared <= 0.0 || radius_squared >= 1.0 do continue
		scale := math.sqrt_f64(-2.0 * math.ln_f64(radius_squared) / radius_squared)
		first, second = u1 * scale, u2 * scale
		accepted = true
		break
	}
	if !accepted do return -1
	if output == nil || capacity < 2 do return -2
	output[0], output[1] = first, second
	return 2
}
