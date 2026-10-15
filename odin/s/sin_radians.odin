package sin_radians

import "core:math"

@(export)
sin_radians :: proc "c" (radians: f64) -> f64 {
	if !(radians >= -1_000_000.0 && radians <= 1_000_000.0) do return -1.0
	x := (3.141592653589793 / 2.0) - radians
	tp := 1.0 / (2.0 * 3.141592653589793)
	x *= tp
	x -= 0.25 + math.floor_f64(x + 0.25)
	absolute := if x < 0.0 { -x } else { x }
	x *= 16.0 * (absolute - 0.5)
	absolute = if x < 0.0 { -x } else { x }
	x += 0.225 * x * (absolute - 1.0)
	return x
}
