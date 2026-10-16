package to_polar_angle_degrees

import "core:math"

INVALID_RESULT :: -1.0e300
PI :: 3.141592653589793238462643383279502884

@(export)
to_polar_angle_degrees :: proc "c" (x, y: f64) -> f64 {
	if x != x || y != y || x < -1000000.0 || x > 1000000.0 ||
		y < -1000000.0 || y > 1000000.0 || (x == 0.0 && y == 0.0) do return INVALID_RESULT
	theta := f64(0.0)
	if x >= 0.0 do theta = math.atan(y / x)
	else do theta = math.atan(y / x) + PI
	return theta * (180.0 / PI)
}
