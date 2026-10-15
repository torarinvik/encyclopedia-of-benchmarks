package cos

import "core:math"

@(export)
cos :: proc "c" (x_value: f64) -> f64 {
	if !(x_value >= -1000000.0 && x_value <= 1000000.0) do return -1.0
	tp := 1.0 / (2.0 * 3.141592653589793)
	x := x_value * tp
	x -= 0.25 + math.floor_f64(x + 0.25)
	absolute := if x < 0.0 { -x } else { x }
	x *= 16.0 * (absolute - 0.5)
	absolute = if x < 0.0 { -x } else { x }
	x += 0.225 * x * (absolute - 1.0)
	return x
}
