package period_of_pendulum

import "core:c"
import "core:math"

PI :: 3.141592653589793238462643383279502884

@(export)
period_of_pendulum :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 1 do return -1.0e300
	pendulum_length := values[0]
	if pendulum_length < 0 || pendulum_length > 1000 do return -1.0e300
	root := math.pow(f64(pendulum_length) / 9.80665, 0.5)
	return (2.0 * PI) * root
}
