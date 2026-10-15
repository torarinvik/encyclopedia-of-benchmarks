package snell_law

import "core:math"

INVALID_RESULT :: f64 = -1.0e300
HALF_PI :: f64 = 1.5707963267948966

@(export)
snell_law :: proc "c" (n1, n2, theta1: f64) -> f64 {
	if math.isnan_f64(n1) || math.isnan_f64(n2) || math.isnan_f64(theta1) ||
		n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 || theta1 < -HALF_PI || theta1 > HALF_PI do return INVALID_RESULT
	ratio := n1 / n2
	sin_theta2 := ratio * math.sin_f64(theta1)
	if math.abs(sin_theta2) > 1.0 do return INVALID_RESULT
	return math.asin_f64(sin_theta2)
}
