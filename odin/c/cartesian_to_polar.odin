package cartesian_to_polar

import "core:math"

// Return radius for component 0 and the atan2 angle for component 1.
@(export)
cartesian_to_polar :: proc "c" (x, y, component: f64) -> f64 {
	if x != x || y != y || (component != 0.0 && component != 1.0) do return -1.0e300
	if x < -1000000.0 || x > 1000000.0 || y < -1000000.0 || y > 1000000.0 do return -1.0e300
	if component == 0.0 do return math.sqrt(x * x + y * y)
	if x == 0.0 && y == 0.0 do return 0.0
	return math.atan2(y, x)
}
